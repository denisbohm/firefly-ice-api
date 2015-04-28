package com.fireflydesign.fireflydevice;

import java.util.List;

public interface FDPullTaskUpload {

    public interface Delegate {

        void uploadComplete(FDPullTaskUpload upload, FDError error);

    }

    Delegate getDelegate();

    void setDelegate(Delegate delegate);

    boolean isConnectionOpen();

    String getSite();

    void post(String site, List<Object> items, int backlog);

    void cancel(FDError error);

}

