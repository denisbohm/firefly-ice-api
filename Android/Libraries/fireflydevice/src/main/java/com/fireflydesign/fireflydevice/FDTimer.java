//
//  FDTimer.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

public class FDTimer {

    public interface Delegate {
        void timerFired();
    }

    public enum Type {OneShot, Repeating}

    double timeout;
    Type type;
    boolean enabled;
    FDTimer.Delegate invocation;

    public void setInvocation(FDTimer.Delegate invocation) {
        this.invocation = invocation;
    }

    public FDTimer.Delegate getInvocation() {
        return invocation;
    }

    public void setTimeout(double timeout) {
        this.timeout = timeout;
    }

    public double getTimeout() {
        return timeout;
    }

    public void setType(Type type) {
        this.type = type;
    }

    public Type getType() {
        return type;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public boolean isEnabled() {
        return enabled;
    }

}
