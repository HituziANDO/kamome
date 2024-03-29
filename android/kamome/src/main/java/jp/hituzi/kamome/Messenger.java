package jp.hituzi.kamome;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.webkit.ValueCallback;
import android.webkit.WebView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

final class Messenger {
    @NonNull
    private static final String jsObj = "window.KM";

    public static void completeMessage(@NonNull final WebView webView, @Nullable final Object data, @NonNull final String requestId) {
        if (data != null) {
            runJavaScript(String.format("%s.onComplete(%s, '%s')", jsObj, data, requestId), webView);
        } else {
            runJavaScript(String.format("%s.onComplete(null, '%s')", jsObj, requestId), webView);
        }
    }

    public static void failMessage(@NonNull final WebView webView, @Nullable final String error, @NonNull final String requestId) {
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

    public static void sendRequest(@NonNull final WebView webView, @NonNull final Request request) {
        if (request.data != null) {
            runJavaScript(String.format("%s.onReceive('%s', %s, '%s')",
                    jsObj, request.name, request.data, request.callbackId), webView);
        } else {
            runJavaScript(String.format("%s.onReceive('%s', null, '%s')",
                    jsObj, request.name, request.callbackId), webView);
        }
    }

    private static void runJavaScript(@NonNull final String js, @NonNull final WebView webView) {
        new Handler(Looper.getMainLooper()).post(() -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                webView.evaluateJavascript(js, value -> {
                    // Nothing to do.
                });
            } else {
                webView.loadUrl("javascript:" + js);
            }
        });
    }
}
