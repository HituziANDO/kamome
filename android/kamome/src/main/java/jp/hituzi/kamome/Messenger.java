package jp.hituzi.kamome;

import android.os.Handler;
import android.os.Looper;
import android.webkit.WebView;

import org.json.JSONObject;

public final class Messenger {

    public static void sendMessage(final WebView webView, final String name, final JSONObject data) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {

            @Override
            public void run() {
                String js;

                if (data != null) {
                    js = String.format("window.Kamome.onReceive('%s', '%s')", name, data.toString());
                } else {
                    js = String.format("window.Kamome.onReceive('%s', null)", name);
                }

                webView.loadUrl("javascript:" + js);
            }
        });
    }
}
