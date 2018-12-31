package jp.hituzi.kamome.internal;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.webkit.WebView;

public final class Messenger {

    public static void completeMessage(final WebView webView, final String name, final Object data) {
        runJavaScript("window.Kamome.onComplete", webView, name, data);
    }

    public static void sendMessage(final WebView webView, final String name, final Object data) {
        runJavaScript("window.Kamome.onReceive", webView, name, data);
    }

    private static void runJavaScript(final String funcName, final WebView webView, final String name, final Object data) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {

            @Override
            public void run() {
                String js;

                if (data != null) {
                    js = String.format("%s('%s', '%s')", funcName, name, data.toString());
                } else {
                    js = String.format("%s('%s', null)", funcName, name);
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    webView.evaluateJavascript(js, null);
                } else {
                    webView.loadUrl("javascript:" + js);
                }
            }
        });
    }
}
