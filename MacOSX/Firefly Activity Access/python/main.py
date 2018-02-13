from activity.cloudkit import CloudKit
from activity.datastore import ActivityDatastore
from activity.datastore import Datastore
import argparse
import datetime
import os


class Main:
    def __init__(self):
        self.datastore_path = os.path.expanduser('~/Downloads/Firefly Activity')
        self.private_key_path = os.path.expanduser('~/Documents/Firefly Activity/eckey.pem')
        self.key_id = None
        with open(os.path.expanduser('~/Documents/Firefly Activity/key_id'), "r") as file:
            self.key_id = file.readline().rstrip()
        self.container = 'iCloud.com.fireflydesign.Firefly-Activity'
        self.environment = 'development'

    def run(self):
        parser = argparse.ArgumentParser()
        parser.add_argument("--sync", action="store_true", help="synchronize local files with those stored in CloudKit")
        parser.add_argument("--list", action="store_true", help="list all installations found in local files")
        parser.add_argument("--test", action="store_true", help="print vmas for first span of first name of first installation")
        args = parser.parse_args()
        if args.sync:
            cloud_kit = CloudKit(self.private_key_path, self.key_id, self.container, self.environment, self.datastore_path)
            cloud_kit.query_files()
        if args.list:
            datastore = Datastore(self.datastore_path)
            installations = datastore.list()
            print(installations)
        if args.test:
            datastore = Datastore(self.datastore_path)
            installations = datastore.list()
            installation = installations[0]
            installation_uuid = installation['installationUUID']
            name_ranges = installation['name_ranges']
            name_range = name_ranges[0]
            name = name_range.name
            hardware_range = name_range.hardware_ranges[0]

            activity = ActivityDatastore(self.datastore_path, installation_uuid, hardware_range.hardware_identifier)
            if hardware_range.start is not None:
                start = hardware_range.start
            else:
                start = datetime.datetime(2016, 1, 19, 9, 47, 0, 432000, tzinfo=pytz.utc).timestamp()
            end = datetime.datetime.now().timestamp()
            spans = activity.query(start, end)
            print(name)
            print(spans)


if __name__ == "__main__":
    main = Main()
    main.run()
