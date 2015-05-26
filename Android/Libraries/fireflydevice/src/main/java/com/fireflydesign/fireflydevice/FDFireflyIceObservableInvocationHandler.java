package com.fireflydesign.fireflydevice;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by denis on 4/11/15.
 */
public class FDFireflyIceObservableInvocationHandler implements InvocationHandler {

    List<FDFireflyIceObserver> observers;

    public static FDFireflyIceObservable newFireflyIceObservable() {
        return (FDFireflyIceObservable) Proxy.newProxyInstance(
            FDFireflyIceObservable.class.getClassLoader(),
            new Class[]{FDFireflyIceObservable.class},
            new FDFireflyIceObservableInvocationHandler()
        );
    }

    FDFireflyIceObservableInvocationHandler() {
        observers = new ArrayList<FDFireflyIceObserver>();
    }

    public void addObserver(FDFireflyIceObserver observer) {
        observers.add(observer);
    }

    public void removeObserver(FDFireflyIceObserver observer) {
        observers.remove(observer);
    }

    public Object invoke(Object proxy, Method method, Object[] args) {
        if (method.getName().equals("addObserver")) {
            addObserver((FDFireflyIceObserver)args[0]);
            return null;
        }

        if (method.getName().equals("removeObserver")) {
            removeObserver((FDFireflyIceObserver)args[0]);
            return null;
        }

        for (FDFireflyIceObserver observer : observers.toArray(new FDFireflyIceObserver[0])) {
            try {
                method.invoke(observer, args);
            } catch (Exception e) {
                except(e);
            }
        }
        return null;
    }

    void except(Exception e) {
    }

}
