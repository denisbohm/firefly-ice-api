package com.fireflydesign.fireflydevice;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by denis on 5/8/15.
 */
public class FDVMADecoder implements FDPullTask.Decoder {

    public Object decode(int type, byte[] data, byte[] responseData) {
        FDBinary binary = new FDBinary(data);
        double time = binary.getUInt32(); // 4-byte time
        int interval = binary.getUInt16();
        int n = binary.getRemainingLength() / 2; // 2 bytes == sizeof(float16)
        FDFireflyDeviceLogger.info(null, "sync VMAs: %d values", n);
        List<Double> vmas = new ArrayList<Double>();
        for (int i = 0; i < n; ++i) {
            double value = binary.getFloat16();
            vmas.add(value);
        }
        FDVMAItem item = new FDVMAItem();
        item.time = time;
        item.interval = interval;
        item.vmas = vmas;
        return item;
    }

}