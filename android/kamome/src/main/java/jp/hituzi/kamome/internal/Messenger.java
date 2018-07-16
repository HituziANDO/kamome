package jp.hituzi.kamome.internal;

import android.os.Handler;
import android.os.Looper;
import android.webkit.WebView;

import org.json.JSONObject;

public final class Messenger {

    public static void completeMessage(final WebView webView, final String name, final JSONObject data) {
        runJavaScript("window.Kamome.onComplete", webView, name, data);
    }

    public static void sendMessage(final WebView webView, final String name, final JSONObject data) {
        runJavaScript("window.Kamome.onReceive", webView, name, data);
    }

    private static void runJavaScript(final String funcName, final WebView webView, final String name, final JSONObject data) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {

            @Override
            public void run() {
                String js;

                if (data != null) {
                    js = String.format("%s('%s', '%s')", funcName, name, data.toString());
                } else {
                    js = String.format("%s('%s', null)", funcName, name);
                }

                webView.loadUrl("javascript:" + js);
            }
        });
    }
}
