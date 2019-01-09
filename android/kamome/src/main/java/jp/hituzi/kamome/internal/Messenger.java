package jp.hituzi.kamome.internal;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.Nullable;
import android.webkit.ValueCallback;
import android.webkit.WebView;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;

public final class Messenger {

    public interface IMessageCallback {

        void onReceiveResult(Object result);
    }

    private static final Object LOCK_OBJECT = new Object();
    private static final HashMap<String, IMessageCallback> MESSAGE_CALLBACKS = new HashMap<>();

    public static void completeMessage(final WebView webView, final String name, @Nullable final Object data) {
        runJavaScript("window.Kamome.onComplete", webView, name, data, null);
    }

    public static void sendMessage(final WebView webView, final String name, @Nullable final Object data,
        @Nullable IMessageCallback callback, @Nullable String callbackId) {

        if (callback != null && callbackId != null) {
            synchronized (LOCK_OBJECT) {
                MESSAGE_CALLBACKS.put(callbackId, callback);
            }
        }

        runJavaScript("window.Kamome.onReceive", webView, name, data, callbackId);
    }

    private static void runJavaScript(final String funcName, final WebView webView, final String name, @Nullable final Object data,
        @Nullable final String callbackId) {

        new Handler(Looper.getMainLooper()).post(new Runnable() {

            @Override
            public void run() {
                String js = String.format("%s('%s', %s, %s)",
                    funcName,
                    name,
                    data != null ? "'" + data.toString() + "'" : "null",
                    callbackId != null ? "'" + callbackId + "'" : "null");

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    webView.evaluateJavascript(js, new ValueCallback<String>() {

                        @Override
                        public void onReceiveValue(String value) {
                            if (value != null && !"null".equalsIgnoreCase(value)) {
                                String id = null;
                                Object result = null;

                                try {
                                    JSONObject obj = new JSONObject(value);
                                    id = obj.getString("callbackId");
                                    result = obj.get("result");
                                } catch (JSONException e) {
                                    e.printStackTrace();
                                }

                                synchronized (LOCK_OBJECT) {
                                    if (MESSAGE_CALLBACKS.containsKey(id)) {
                                        MESSAGE_CALLBACKS.remove(id).onReceiveResult(result);
                                    }
                                }
                            }
                        }
                    });
                } else {
                    // MessageCallback not supported.
                    webView.loadUrl("javascript:" + js);
                }
            }
        });
    }
}
