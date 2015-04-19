//
//  FDFireflyIceSimpleTask.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 10/17/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

public class FDFireflyIceSimpleTask extends FDFireflyIceTaskSteps {

    public interface Delegate {
        void run();
    }

    Delegate delegate;

	public FDFireflyIceSimpleTask(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, Delegate delegate) {
		super(fireflyIce, channel);
		this.delegate = delegate;
	}

	public void executorTaskStarted(FDExecutor executor) {
		super.executorTaskStarted(executor);
		delegate.run();
		next("complete");
	}

	void complete() {
		done();
	}

}
