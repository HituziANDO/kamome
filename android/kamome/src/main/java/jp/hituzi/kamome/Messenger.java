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
        final String id = escapeForJSStringLiteral(requestId);
        if (data != null) {
            runJavaScript(String.format("%s.onComplete(%s, '%s')", jsObj, data, id), webView);
        } else {
            runJavaScript(String.format("%s.onComplete(null, '%s')", jsObj, id), webView);
        }
    }

    public static void failMessage(@NonNull final WebView webView, @Nullable final String error, @NonNull final String requestId) {
        final String id = escapeForJSStringLiteral(requestId);
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
            runJavaScript(String.format("%s.onError('%s', '%s')", jsObj, errMsg, id), webView);
        } else {
            runJavaScript(String.format("%s.onError(null, '%s')", jsObj, id), webView);
        }
    }

    public static void sendRequest(@NonNull final WebView webView, @NonNull final Request request) {
        final String name = escapeForJSStringLiteral(request.name);
        final String callbackId = escapeForJSStringLiteral(request.callbackId);
        if (request.data != null) {
            runJavaScript(String.format("%s.onReceive('%s', %s, '%s')",
                    jsObj, name, request.data, callbackId), webView);
        } else {
            runJavaScript(String.format("%s.onReceive('%s', null, '%s')",
                    jsObj, name, callbackId), webView);
        }
    }

    /**
     * Escapes a string for safe interpolation inside a single-quoted JavaScript string literal.
     */
    @NonNull
    static String escapeForJSStringLiteral(@NonNull final String value) {
        final StringBuilder sb = new StringBuilder(value.length());
        for (int i = 0; i < value.length(); i++) {
            final char c = value.charAt(i);
            switch (c) {
                case '\\': sb.append("\\\\"); break;
                case '\'': sb.append("\\'"); break;
                case '"': sb.append("\\\""); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                case '\u2028': sb.append("\\u2028"); break;
                case '\u2029': sb.append("\\u2029"); break;
                default:
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
            }
        }
        return sb.toString();
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
