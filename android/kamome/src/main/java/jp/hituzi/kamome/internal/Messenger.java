package jp.hituzi.kamome.internal;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.Nullable;
import android.webkit.ValueCallback;
import android.webkit.WebView;

public final class Messenger {

    public static void completeMessage(final WebView webView, @Nullable final Object data, String requestId) {
        if (data != null) {
            runJavaScript(String.format("window.Kamome.onComplete('%s', '%s')", data.toString(), requestId), webView);
        } else {
            runJavaScript(String.format("window.Kamome.onComplete(null, '%s')", requestId), webView);
        }
    }

    public static void failMessage(final WebView webView, @Nullable final String error, String requestId) {
        if (error != null) {
            runJavaScript(String.format("window.Kamome.onError('%s', '%s')", error, requestId), webView);
        } else {
            runJavaScript(String.format("window.Kamome.onError(null, '%s')", requestId), webView);
        }
    }

    public static void sendMessage(final WebView webView, final String name, @Nullable final Object data, @Nullable String callbackId) {
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
                            // Nothing to do.
                        }
                    });
                } else {
                    webView.loadUrl("javascript:" + js);
                }
            }
        });
    }
}
