package jp.hituzi.kamome.internal;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.Nullable;
import android.webkit.ValueCallback;
import android.webkit.WebView;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

public final class Messenger {

    private static final String jsObj = "window.KM";

    public static void completeMessage(final WebView webView, @Nullable final Object data, String requestId) {
        if (data != null) {
            runJavaScript(String.format("%s.onComplete(%s, '%s')", jsObj, data.toString(), requestId), webView);
        } else {
            runJavaScript(String.format("%s.onComplete(null, '%s')", jsObj, requestId), webView);
        }
    }

    public static void failMessage(final WebView webView, @Nullable final String error, String requestId) {
        if (error != null) {
            String errMsg;
            try {
                errMsg = URLEncoder.encode(error, "utf-8");
                // The URLEncoder converts spaces to '+' and
                // the `decodeURIComponent` function on JS decodes '%20' to spaces.
                errMsg = errMsg.replaceAll("\\+", "%20");
            } catch (UnsupportedEncodingException e) {
                errMsg = error;
            }
            runJavaScript(String.format("%s.onError('%s', '%s')", jsObj, errMsg, requestId), webView);
        } else {
            runJavaScript(String.format("%s.onError(null, '%s')", jsObj, requestId), webView);
        }
    }

    public static void sendMessage(final WebView webView, final String name, @Nullable final Object data, @Nullable String callbackId) {
        if (data != null) {
            if (callbackId != null) {
                runJavaScript(String.format("%s.onReceive('%s', %s, '%s')", jsObj, name, data.toString(), callbackId), webView);
            } else {
                runJavaScript(String.format("%s.onReceive('%s', %s, null)", jsObj, name, data.toString()), webView);
            }
        } else {
            if (callbackId != null) {
                runJavaScript(String.format("%s.onReceive('%s', null, '%s')", jsObj, name, callbackId), webView);
            } else {
                runJavaScript(String.format("%s.onReceive('%s', null, null)", jsObj, name), webView);
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
