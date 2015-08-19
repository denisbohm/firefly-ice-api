package com.fireflydesign.fireflydevice;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by denis on 8/14/15.
 */
public class FDObservable {

    class Handler implements InvocationHandler {

        Class observerInterface;

        Handler(Class observerInterface) {
            this.observerInterface = observerInterface;
        }

        public Object invoke(Object proxy, Method method, Object[] args) {
            for (Object observer : observers.toArray(new Object[0])) {
                if (observerInterface.isInstance(observer)) {
                    try {
                        method.invoke(observer, args);
                    } catch (Exception e) {
                        except(e);
                    }
                }
            }
            return null;
        }

    }

    List<Object> observers;
    Map<Class, Object> proxyByObserverInterface;

    public FDObservable() {
        observers = new ArrayList<Object>();
        proxyByObserverInterface = new HashMap<Class, Object>();
    }

    public void addObserver(Object observer) {
        observers.add(observer);
    }

    public void removeObserver(Object observer) {
        observers.remove(observer);
    }

    public <T> T as(Class<T> observerInterface) {
        return (T) proxyByObserverInterface.get(observerInterface);
    }

    public void addObserverInterface(Class observerInterface) {
        ClassLoader classLoader = observerInterface.getClassLoader();
        Handler handler = new Handler(observerInterface);
        Object proxy = Proxy.newProxyInstance(
                classLoader,
                new Class[] {observerInterface},
                handler
        );
        proxyByObserverInterface.put(observerInterface, proxy);
    }

    public void except(Exception e) {
    }

}
