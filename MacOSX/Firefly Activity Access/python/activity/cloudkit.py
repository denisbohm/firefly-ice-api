import base64
import datetime
import ecdsa
import hashlib
import json
import os
import pytz
import requests
from requests.auth import AuthBase


# https://developer.apple.com/library/content/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW1
class CloudKitAuth(AuthBase):
    def __init__(self, key_id, key_file_name):
        self.key_id = key_id
        self.key_file_name = key_file_name

    def __call__(self, request):
        now = datetime.datetime.now(tz=pytz.UTC)
        now = now.replace(microsecond=0)
        formatted_date = now.isoformat().replace("+00:00", "Z")

        body = request.body or ''
        hashed = hashlib.sha256(body.encode('utf-8'))
        encoded_body = base64.b64encode(hashed.digest())
        message = "{}:{}:{}".format(formatted_date, encoded_body.decode('utf-8'), request.path_url).encode('utf-8')
        signing_key = ecdsa.SigningKey.from_pem(open(self.key_file_name).read())
        unencoded_signature = signing_key.sign(message, hashfunc=hashlib.sha256, sigencode=ecdsa.util.sigencode_der)
        signature = base64.b64encode(unencoded_signature).decode('utf-8')

        request.headers = {
            'Content-Type': 'application/json',
            'X-Apple-CloudKit-Request-KeyID': self.key_id,
            'X-Apple-CloudKit-Request-ISO8601Date': formatted_date,
            'X-Apple-CloudKit-Request-SignatureV1': signature
        }
        return request


class CloudKit:
    def __init__(self, private_key_path, key_id, container, environment, datastore_path):
        self.private_key_path = private_key_path
        self.key_id = key_id
        self.base_url = 'https://api.apple-cloudkit.com/database/1/' + container + '/' + environment + '/'
        self.datastore_path = datastore_path

    def get_file(self, path, modification_time_ms, download_url):
        auth = CloudKitAuth(key_id=self.key_id, key_file_name=self.private_key_path)
        download_response = requests.get(download_url, auth=auth)
        download_response.raise_for_status()
        json.loads(download_response.content)
        content = download_response.content
        directory = os.path.dirname(path)
        if not os.path.exists(directory):
            os.makedirs(directory)
        with open(path, "wb") as file:
            file.write(content)
        time_in_ns = modification_time_ms * 1000000
        # add a millisecond to handle case where date representations do not have the same resolution
        # (also possibly due to very small number conversion issues) -denis
        time_in_ns = time_in_ns + 1000000
        os.utime(path, ns=(time_in_ns, time_in_ns))

    def is_out_of_date(self, path, modification_time_ms):
        try:
            stat = os.stat(path)
        except FileNotFoundError:
            return True
        return (modification_time_ms * 1000000) > stat.st_mtime_ns

    def query_files(self):
        records = []
        continuation_marker = None
        while True:
            url = self.base_url + 'public/records/query'
            auth = CloudKitAuth(key_id=self.key_id, key_file_name=self.private_key_path)
            data = {
              "zoneID": {
                "zoneName": "_defaultZone",
              },
              "query": {
                "recordType": "File",
                "desiredKeys": [
                    "installationUUID", "path", "fileModificationDate"
                ]
              }
            }
            if continuation_marker is not None:
                data["continuationMarker"] = continuation_marker
            response = requests.post(url, auth=auth, data=json.dumps(data))
            response_json = response.json()
            records.extend(response_json['records'])
            if 'continuationMarker' in response_json:
                continuation_marker = response_json['continuationMarker']
            else:
                break

        for record in records:
            fields = record['fields']
            installation_uuid = fields['installationUUID']['value']
            path = fields['path']['value']
            modification_date_ms = fields['fileModificationDate']['value']
            download_url = fields['data']['value']['downloadURL']
            local_path = self.datastore_path + '/' + installation_uuid + '/' + path
            if self.is_out_of_date(local_path, modification_date_ms):
                print('getting ' + local_path)
                self.get_file(local_path, modification_date_ms, download_url)

