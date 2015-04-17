package com.fireflydesign.fireflydevice;

public class FDFireflyIceLock {

    public static class Owner {

        public static int encode(char a, char b, char c, char d) { return (a << 24) | (b << 16) | (c << 8) | d; }

        public final static Owner None = new Owner(0);
        public final static Owner BLE = new Owner(encode('B', 'L', 'E', ' '));
        public final static Owner USB = new Owner(encode('U', 'S', 'B', ' '));

        int code;

        public Owner(int code) {
            this.code = code;
        }

        public String name() {
            if (code == None.code) {
                return "none";
            }
            if (code == BLE.code) {
                return "ble";
            }
            if (code == USB.code) {
                return "usb";
            }
            return Integer.toString(code, 16);
        }

    }

    public enum Operation {
        None,
        Acquire,
        Release,
    }

    public enum Identifier {
        Sync,
        Update,
    }

    Identifier identifier;
    Operation operation;
    Owner owner;

    String identifierName() {
        return identifier.name();
    }

    String operationName() {
        return operation.name();
    }

    String ownerName() {
        return owner.name();
    }

    String description() {
        return FDString.format("lock identifier %s operation %s owner %s", identifierName(), operationName(), ownerName());
    }

}
