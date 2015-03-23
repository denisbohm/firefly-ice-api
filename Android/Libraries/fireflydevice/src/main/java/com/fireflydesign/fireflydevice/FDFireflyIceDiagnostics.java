package com.fireflydesign.fireflydevice;

public class FDFireflyIceDiagnostics {

    public int flags;
    public FDFireflyIceDiagnosticsBLE[] values;

    public String description() {
        String s = "diagnostics";
        for (FDFireflyIceDiagnosticsBLE value : values) {
            s += " " + value.description();
        }
        return s;
    }

}
