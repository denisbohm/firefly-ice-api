//
//  FDDetourSource.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class FDDetourSource {

    int size;
    List<Byte> data;
    int index;
    byte sequenceNumber;

    public FDDetourSource(int size, List<Byte> bytes) {
        this.size = size;
        data = new ArrayList<Byte>();
        int length = bytes.size();
        Byte[] lengthBytes = { (byte)(length), (byte)(length >> 8) };
        data.addAll(Arrays.asList(lengthBytes));
        data.addAll(bytes);
	}

	public List<Byte> next() {
		if (index >= data.size()) {
			return new ArrayList<Byte>();
		}

		int n = data.size() - index;
		if (n > (size - 1)) {
			n = size - 1;
		}
		List<Byte> subdata = new ArrayList<Byte>();
		subdata.add(sequenceNumber);
        subdata.addAll(data.subList(index, index + n));
		index += n;
		++sequenceNumber;
		return subdata;
	}

}
