//
//  FDTimer.h
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDTIMER_H
#define FDTIMER_H

#include "FDCommon.h"

#include <functional>
#include <memory>

namespace FireflyDesign {

	class FDTimerFactory;

	class FDTimer {
	public:
		typedef double duration_type;
		enum Type {OneShot, Repeating};

		virtual ~FDTimer();

		virtual void setInvocation(std::function<void()> invocation) = 0;
		virtual std::function<void()> getInvocation() = 0;

		virtual void setTimeout(duration_type timeout) = 0;
		virtual duration_type getTimeout() = 0;

		virtual void setType(Type type) = 0;
		virtual Type getType() = 0;

		virtual void setEnabled(bool enabled) = 0;
		virtual bool isEnabled() = 0;
	};

	class FDTimerFactory {
	public:
		static std::shared_ptr<FDTimerFactory> defaultTimerFactory;

		virtual ~FDTimerFactory();

		virtual std::shared_ptr<FDTimer> makeTimer(std::function<void()> invocation, FDTimer::duration_type timeout, FDTimer::Type type) = 0;
	};

}

#endif