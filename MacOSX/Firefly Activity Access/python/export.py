# https://developer.apple.com/library/content/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW1

import base64
import datetime
from dateutil import parser
import ecdsa
import hashlib
import json
import os
import pytz
import requests
from requests.auth import AuthBase
import struct


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
    def __init__(self, cloudkit_private_key_path, cloudkit_key_id, cloudkit_base_url, datastore_path):
        self.cloudkit_private_key_path = cloudkit_private_key_path
        self.cloudkit_key_id = cloudkit_key_id
        self.cloudkit_base_url = cloudkit_base_url
        self.datastore_path = datastore_path

    def get_file(self, path, modification_time_ms, download_url):
        auth = CloudKitAuth(key_id=self.cloudkit_key_id, key_file_name=self.cloudkit_private_key_path)
        download_response = requests.get(download_url, auth=auth)
        content = download_response.content
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
            url = self.cloudkit_base_url + 'public/records/query'
            auth = CloudKitAuth(key_id=self.cloudkit_key_id, key_file_name=self.cloudkit_private_key_path)
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


class HardwareRange:
    def __init__(self, hardware_identifier=None, start=None, end=None):
        self.hardware_identifier = hardware_identifier
        self.start = start
        self.end = end

    def __repr__(self):
        return "HardwareRange(" + repr(self.hardware_identifier) + ", " + repr(self.start) + ", " + repr(self.end) + ")"


class NameRange:
    def __init__(self, name, hardware_ranges):
        self.name = name
        self.hardware_ranges = hardware_ranges

    def __repr__(self):
        return "NameRange(" + repr(self.name) + ", " + repr(self.hardware_ranges) + ")"


class Naming:
    def __init__(self, name, hardware_identifier, start):
        self.name = name
        self.hardware_identifier = hardware_identifier
        self.start = start
        self.hardware_ranges = []


class NameRangeExtractor:
    def __init__(self):
        self.namingByName = {}

    def process(self, item):
        type = item['type']
        try:
            method = getattr(self, type)
            method(item)
        except AttributeError:
            pass

    def nameDevice(self, item):
        date = parser.parse(item['date']).timestamp()
        value = item['value']
        name = value['name']
        hardware_identifier = value['hardwareIdentifier']
        naming = self.namingByName.get(name)
        if naming is None:
            self.namingByName[name] = Naming(name, hardware_identifier, date)
        else:
            if naming.hardware_identifier is None:
                naming.hardware_identifier = hardware_identifier
                naming.start = date
            else:
                if naming.hardware_identifier != hardware_identifier:
                    naming.hardware_ranges.append(HardwareRange(naming.hardware_identifier, naming.start, date))
                    naming.hardware_identifier = hardware_identifier
                    naming.start = date

    def forgetDevice(self, item):
        date = parser.parse(item['date']).timestamp()
        value = item['value']
        name = value['name']
        hardware_identifier = value['hardwareIdentifier']
        naming = self.namingByName.get(name)
        if naming is None:
            naming = Naming(name, None, None)
            self.namingByName[name] = naming
        naming.hardware_ranges.append(HardwareRange(naming.hardware_identifier, naming.start, date))
        naming.hardware_identifier = None
        naming.start = None

    def name_ranges(self):
        name_ranges = []
        for name, naming in self.namingByName.items():
            if naming.start is not None:
                naming.hardware_ranges.append(HardwareRange(naming.hardware_identifier, naming.start, None))
                name_ranges.append(NameRange(name, naming.hardware_ranges))
        return name_ranges


class Datastore:
    def __init__(self, path):
        self.path = path

    def list(self):
        installations = []
        installation_uuids = os.listdir(self.path)
        for installation_uuid in installation_uuids:
            installation_uuid_path = os.path.join(self.path, installation_uuid)
            name_range_extractor = NameRangeExtractor()
            datastores = os.listdir(installation_uuid_path)
            for datastore in datastores:
                datastore_path = os.path.join(installation_uuid_path, datastore)
                if datastore == 'history':
                    days = sorted(os.listdir(datastore_path))
                    for day in days:
                        day_path = os.path.join(datastore_path, day)
                        with open(day_path) as file:
                            for _, line in enumerate(file):
                                item = json.loads(line)
                                name_range_extractor.process(item)
                elif datastore.startswith('FireflyIce-'):
                    pass
            installations.append({"installationUUID": installation_uuid, "name_ranges": name_range_extractor.name_ranges()})
        return installations


class ActivitySpan:
    def __init__(self, time, interval, vmas):
        self.time = time
        self.interval = interval
        self.vmas = vmas

    def __repr__(self):
        return "ActivitySpan(" + repr(self.time) + ", " + repr(self.interval) + ", " + repr(self.vmas) + ")"


class FDBinary:
    def __init__(self, data):
        self.data = data
        self.index = 0

    def get_remaining_length(self):
        return len(self.data) - self.index

    def get_uint32(self):
        value = struct.unpack('<I', self.data[self.index:self.index + 4])[0]
        self.index += 4
        return value

    def get_float32(self):
        value = struct.unpack('<f', self.data[self.index:self.index + 4])[0]
        self.index += 4
        return value


class ActivityDatastore:
    def __init__(self, root, installation_uuid, hardware_identifier):
        self.bytes_per_record = 8
        self.interval = 10
        self.extension = ".dat"
        self.root = root
        self.installation_uuid = installation_uuid
        self.hardware_identifier = hardware_identifier
        self.data = None
        self.start = None
        self.end = None

    def load(self, day):
        start = datetime.datetime.strptime(day + " UTC", "%Y-%m-%d %Z")
        self.start = start.timestamp()
        self.end = (start + datetime.timedelta(days=1)).timestamp()
        path = os.path.join(self.root, self.installation_uuid, self.hardware_identifier, day + self.extension)
        with open(path, "rb") as file:
            self.data = file.read()

    def days_in_range(self, start, end):
        days = []
        start_of_day = datetime.datetime.fromtimestamp(start).replace(hour=0, minute=0, second=0, microsecond=0)
        end_datetime = datetime.datetime.fromtimestamp(end)
        while start_of_day < end_datetime:
            days.append(start_of_day.strftime("%Y-%m-%d"))
            start_of_day += datetime.timedelta(days=1)
        return days

    def query(self, start, end):
        spans = []
        vmas = []
        last_time = 0
        days = self.days_in_range(start, end)
        for day in days:
            try:
                self.load(day)
            except:
                continue

            time = self.start
            binary = FDBinary(self.data)
            while binary.get_remaining_length() > self.bytes_per_record:
                flags = binary.get_uint32()
                vma = binary.get_float32()
                if (start < time) and (time < end):
                    valid = flags != 0
                    if valid:
                        if not vmas:
                            last_time = time
                        vmas.append(vma)
                    else:
                        if vmas:
                            spans.append(ActivitySpan(last_time, self.interval, list(vmas)))
                            last_time = 0
                            vmas.clear()
                time += self.interval
        if vmas:
            spans.append(ActivitySpan(last_time, self.interval, vmas))
        return spans


datastore_path = '/Users/denis/Downloads/Firefly Activity'

cloud_kit = CloudKit(
    '/Users/denis/sandbox/denisbohm/firefly-ice-api/MacOSX/Firefly Activity Access/python/eckey.pem',
    '50d006025da2466b0462d6c670d059124bf4d843177b05f4e03265f6789a7676',
    'https://api.apple-cloudkit.com/database/1/iCloud.com.fireflydesign.Firefly-Activity/development/',
    datastore_path)
cloud_kit.query_files()

datastore = Datastore(datastore_path)
installations = datastore.list()

installation = installations[0]
installation_uuid = installation['installationUUID']
name_ranges = installation['name_ranges']
name_range = name_ranges[0]
name = name_range.name
hardware_range = name_range.hardware_ranges[0]

activity = ActivityDatastore(datastore_path, installation_uuid, hardware_range.hardware_identifier)
if hardware_range.start is not None:
    start = hardware_range.start
else:
    start = datetime.datetime(2016, 1, 19, 9, 47, 0, 432000, tzinfo=pytz.utc).timestamp()
end = datetime.datetime.now().timestamp()
spans = activity.query(start, end)
print(name)
print(spans)
