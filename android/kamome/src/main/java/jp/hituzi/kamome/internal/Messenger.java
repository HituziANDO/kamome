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
        if (data != null) {
            runJavaScript(String.format("window.Kamome.onComplete('%s', '%s', null)", name, data.toString()), webView);
        } else {
            runJavaScript(String.format("window.Kamome.onComplete('%s', null, null)", name), webView);
        }
    }

    public static void failMessage(final WebView webView, final String name, @Nullable final String error) {
        if (error != null) {
            runJavaScript(String.format("window.Kamome.onError('%s', '%s')", name, error), webView);
        } else {
            runJavaScript(String.format("window.Kamome.onError('%s', null)", name), webView);
        }
    }

    public static void sendMessage(final WebView webView, final String name, @Nullable final Object data,
        @Nullable IMessageCallback callback, @Nullable String callbackId) {

        if (callback != null && callbackId != null) {
            synchronized (LOCK_OBJECT) {
                MESSAGE_CALLBACKS.put(callbackId, callback);
            }
        }

        if (data != null) {
            if (callbackId != null) {
                runJavaScript(String.format("window.Kamome.onReceive('%s', '%s', '%s')", name, data.toString(), callbackId), webView);
            } else {
                runJavaScript(String.format("window.Kamome.onReceive('%s', '%s', null)", name, data.toString()), webView);
            }
        } else {
            if (callbackId != null) {
                runJavaScript(String.format("window.Kamome.onReceive('%s', null, '%s')", name, callbackId), webView);
            } else {
                runJavaScript(String.format("window.Kamome.onReceive('%s', null, null)", name), webView);
            }
        }
    }

    private static void runJavaScript(final String js, final WebView webView) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {

            @Override
            public void run() {
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
