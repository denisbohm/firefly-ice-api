//
//  FireflyDevice.h
//  FireflyDevice
//
//  Created by Denis Bohm on 10/13/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FIREFLYDEVICE_H
#define FIREFLYDEVICE_H

#include "FDHardwareId.h"
#include "FDBundle.h"
#include "FDBundleManager.h"
#include "FDFireflyDeviceLogger.h"
#include "FDFileLog.h"
#include "FDBinary.h"
#include "FDCrypto.h"
#include "FDDetour.h"
#include "FDDetourSource.h"
#include "FDIntelHex.h"
#include "FDExecutor.h"
#include "FDFireflyIce.h"
#include "FDFireflyIceChannel.h"
#include "FDFireflyIceChannelUSB.h"
#include "FDFireflyIceCoder.h"
#include "FDFireflyIceTaskSteps.h"
#include "FDHelloTask.h"
#include "FDSyncTask.h"
#include "FDFirmwareUpdateTask.h"
#include "FDFireflyIceSimpleTask.h"

namespace FireflyDesign {

    class FireflyDevice {
	public:
		FireflyDevice();
		~FireflyDevice();
    };

}

#endif
