//
//  FDExecutor.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FDExecutor {

    public final static String FDExecutorErrorDomain = "com.fireflydesign.device.FDExecutor";

    public abstract static class Task {

        double timeout;
        int priority;
        boolean isSuspended;
        double appointment;

        public Task() {
            timeout = 10;
            priority = 0;
            isSuspended = false;
            appointment = 0;
        }

        public abstract void executorTaskStarted(FDExecutor executor);
        public abstract void executorTaskSuspended(FDExecutor executor);
        public abstract void executorTaskResumed(FDExecutor executor);
        public abstract void executorTaskCompleted(FDExecutor executor);
        public abstract void executorTaskFailed(FDExecutor executor, FDError error);
        
    }

    enum FDExecutorErrorCode {
        Abort,
        Cancel,
        Timeout,
    }

    public FDFireflyDeviceLog log;
    public double timeoutCheckInterval;

    List<Task> tasks;
    List<Task> appointmentTasks;
    Task currentTask;
    FDTimerFactory timerFactory;
    boolean run;
    double currentFeedTime;
    FDTimer timer;

    public FDExecutor() {
		timeoutCheckInterval = 5;
        timerFactory = new FDTimerFactory();
		run = false;
		currentFeedTime = 0;
	}

	public void dispose() {
		cancelTimer();
	}

	void cancelTimer() {
		if (timer != null) {
			timer.setEnabled(false);
			timer = null;
		}
	}

	void start() {
		if (timer == null) {
			timer = timerFactory.makeTimer(new FDTimer.Delegate() {
                public void timerFired() {
                    check();
                }
            }, timeoutCheckInterval, FDTimer.Type.Repeating);
		}
		timer.setEnabled(true);
		schedule();
	}

	void abortTask(Task task) {
		try {
			Map<String, String> userInfo = new HashMap<String, String>();
            userInfo.put(FDError.FDLocalizedDescriptionKey, "executor task was aborted");
			task.executorTaskFailed(this, FDError.error(FDExecutorErrorDomain, FDExecutorErrorCode.Abort.ordinal(), userInfo));
		} catch (Exception e) {
			taskException(e);
		}
	}

	void abortTasks(List<Task> tasks) {
		for (Task task : tasks) {
			abortTask(task);
		}
		tasks.clear();
	}

	void stop() {
		cancelTimer();

		if (currentTask != null) {
			abortTask(currentTask);
			currentTask = null;
		}
		abortTasks(appointmentTasks);
		abortTasks(tasks);
	}

	public boolean getRun() {
		return run;
	}

	public void setRun(boolean run) {
		if (this.run == run) {
			return;
		}

		this.run = run;
		if (run) {
			start();
		} else {
			stop();
		}
	}

	void sortTasksByPriority() {
		Collections.sort(tasks, new Comparator<Task>() {
            public int compare(Task a, Task b) {
                return a.priority - b.priority;
            }
		});
	}

	void checkAppointments() {
		List<Task> tasks = new ArrayList<Task>(appointmentTasks);
		double now = FDTime.time();
		for (Task task : tasks) {
			if ((now - task.appointment) >= 0) {
				task.appointment = 0;
				appointmentTasks.remove(task);
				tasks.add(task);
			}
		}
		sortTasksByPriority();
		schedule();
	}

	void addTask(Task task) {
		if (task.appointment != 0) {
			appointmentTasks.add(task);
			return;
		}

		tasks.add(task);
		sortTasksByPriority();
	}

	void checkTimeout() {
		if (currentTask == null) {
			return;
		}

		double duration = FDTime.time() - currentFeedTime;
		if (duration > currentTask.timeout) {
			FDFireflyDeviceLogger.info(log, "executor task timeout");
			Map<String, String> userInfo = new HashMap<String, String>();
            userInfo.put(FDError.FDLocalizedDescriptionKey, "executor task timed out");
			fail(currentTask, FDError.error(FDExecutorErrorDomain, FDExecutorErrorCode.Timeout.ordinal(), userInfo));
		}
	}

	void check() {
		checkTimeout();
		checkAppointments();
	}

	void taskException(Exception e) {
		FDFireflyDeviceLogger.warn(log, "task exception %s", e.toString());
	}

	void schedule() {
		if (!run) {
			return;
		}

		if (currentTask != null) {
			if (tasks.size() == 0) {
				return;
			}
			Task task = tasks.get(0);
			if (currentTask.priority >= task.priority) {
				return;
			}
			Task saveCurrentTask = currentTask;
			currentTask = null;
			saveCurrentTask.isSuspended = true;
			addTask(saveCurrentTask);
			try {
				saveCurrentTask.executorTaskSuspended(this);
			} catch (Exception e) {
				taskException(e);
			}
		}
		if (tasks.size() == 0) {
			return;
		}

		currentTask = tasks.get(0);
		tasks.remove(0);
		currentFeedTime = FDTime.time();
		if (currentTask.isSuspended) {
			currentTask.isSuspended = false;
			try {
				currentTask.executorTaskResumed(this);
			} catch (Exception e) {
				taskException(e);
			}
		} else {
			try {
				currentTask.executorTaskStarted(this);
			} catch (Exception e) {
				taskException(e);
			}
		}
	}

	public void execute(Task task) {
		cancel(task);
		addTask(task);

		schedule();
	}

	public void feedWatchdog(Task task) {
		if (currentTask == task) {
			currentFeedTime = FDTime.time();
		} else {
			FDFireflyDeviceLogger.warn(log, "expected current task to feed watchdog...");
		}
	}

	void over(Task task, FDError error) {
		if (currentTask == task) {
			currentTask = null;
			try {
				if (error == null) {
					task.executorTaskCompleted(this);
				} else {
					task.executorTaskFailed(this, error);
				}
			} catch (Exception e) {
				taskException(e);
			}
			schedule();
		} else {
			FDFireflyDeviceLogger.warn(log, "expected current task to be complete...");
		}
	}

    public void fail(Task task, FDError error) {
		over(task, error);
	}

	public void complete(Task task) {
		over(task, null);
	}

    public void cancel(Task task) {
		if (currentTask == task) {
			Map<String, String> userInfo = new HashMap<String, String>();
            userInfo.put(FDError.FDLocalizedDescriptionKey, "executor task was canceled");
			fail(task, FDError.error(FDExecutorErrorDomain, FDExecutorErrorCode.Cancel.ordinal(), userInfo));
		}
		tasks.remove(task);
		appointmentTasks.remove(task);
	}

	public Task[] allTasks() {
		List<Task> allTasks = new ArrayList<Task>();
		if (currentTask != null) {
			allTasks.add(currentTask);
		}
		allTasks.addAll(tasks);
		allTasks.addAll(appointmentTasks);
		return allTasks.toArray(new Task[0]);
	}

    public boolean hasTasks() {
		return (currentTask != null) || (tasks.size() > 0) || (appointmentTasks.size() > 0);
	}

}
