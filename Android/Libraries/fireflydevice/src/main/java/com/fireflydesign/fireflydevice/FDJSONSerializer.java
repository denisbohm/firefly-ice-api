package com.fireflydesign.fireflydevice;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Created by denis on 8/13/15.
 */
public class FDJSONSerializer {

    public final class Context {
        int count;
    }

    StringBuilder stringBuilder;
    List<Context> contexts;

    public FDJSONSerializer() {
        stringBuilder = new StringBuilder();
        contexts = new ArrayList<Context>();
    }

    public static byte[] serialize(Object object) {
        FDJSONSerializer serializer = new FDJSONSerializer();
        serializer.value(object);
        try {
            return serializer.stringBuilder.toString().getBytes("UTF-8");
        } catch (Exception e) {
            return new byte[0];
        }
    }

    public void objectBegin() {
        contexts.add(new Context());
        stringBuilder.append("{");
    }

    public void next() {
        Context context = contexts.get(contexts.size() - 1);
        if (context.count > 0) {
            stringBuilder.append(",");
        }
        ++context.count;
    }

    public void objectValue(Object value, String key) {
        next();
        putString(key);
        stringBuilder.append(":");
        value(value);
    }

    public void objectNumber(double value, String key) {
        next();
        putString(key);
        stringBuilder.append(":");
        putNumber(value);
    }

    public void objectBoolean(boolean value, String key) {
        next();
        putString(key);
        stringBuilder.append(":");
        putBoolean(value);
    }

    public void objectEnd() {
        contexts.remove(contexts.size() - 1);
        stringBuilder.append("}");
    }

    public void arrayBegin() {
        contexts.add(new Context());
        stringBuilder.append("[");
    }

    public void arrayValue(Object value) {
        next();
        value(value);
    }

    public void arrayNumber(double value) {
        next();
        putNumber(value);
    }

    public void arrayBoolean(boolean value) {
        next();
        putBoolean(value);
    }

    public void arrayEnd() {
        contexts.remove(contexts.size() - 1);
        stringBuilder.append("]");
    }

    public void putString(String value) {
        stringBuilder.append("\"");
        byte[] data = null;
        try {
            data = value.getBytes("UTF-8");
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        for (int i = 0; i < data.length; ++i) {
            byte c = data[i];
            switch (c) {
                case '\\':
                    stringBuilder.append("\\\\");
                    break;
                case '\"':
                    stringBuilder.append("\\\"");
                    break;
                case '/':
                    stringBuilder.append("\\/");
                    break;
                case '\b':
                    stringBuilder.append("\\b");
                    break;
                case '\f':
                    stringBuilder.append("\\f");
                    break;
                case '\n':
                    stringBuilder.append("\\n");
                    break;
                case '\r':
                    stringBuilder.append("\\r");
                    break;
                case '\t':
                    stringBuilder.append("\\t");
                    break;
                default:
                    stringBuilder.append((char) c);
                    break;
            }
        }
        stringBuilder.append("\"");
    }

    public void putNumber(double value) {
        int valueUInt32 = (int)value;
        if (value == valueUInt32) {
            stringBuilder.append(String.format("%d", valueUInt32));
        } else {
            stringBuilder.append(String.format("%f", value));
        }
    }

    public void putBoolean(boolean value) {
        stringBuilder.append(value ? "true" : "false");
    }

    public void putNull() {
        stringBuilder.append("null");
    }

    public void putObject(Map<String, ?> map) {
        objectBegin();
        for (String key : map.keySet()) {
            Object value = map.get(key);
            objectValue(value, key);
        }
        objectEnd();
    }

    public void putArray(List<?> array) {
        arrayBegin();
        for (Object value : array) {
            arrayValue(value);
        }
        arrayEnd();
    }

    public void value(Object object) {
        if (object == null) {
            putNull();
        } else
        if (object == Boolean.TRUE) {
            putBoolean(true);
        } else
        if (object == Boolean.FALSE) {
            putBoolean(false);
        } else
        if (object instanceof Map) {
            putObject((Map<String, ?>) object);
        } else
        if (object instanceof List) {
            putArray((List<?>)object);
        } else
        if (object instanceof String) {
            putString((String)object);
        } else
        if (object instanceof Number) {
            putNumber(((Number) object).doubleValue());
        } else
        if (object instanceof FDJSONSerializable) {
            FDJSONSerializable serializable = (FDJSONSerializable)object;
            serializable.serialize(this);
        } else {
            throw new RuntimeException(String.format("object is not serializable: %s", object.getClass().getName()));
        }
    }

}
