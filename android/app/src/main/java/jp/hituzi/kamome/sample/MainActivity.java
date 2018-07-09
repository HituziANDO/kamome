package jp.hituzi.kamome.sample;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;

import org.json.JSONException;
import org.json.JSONObject;

import jp.hituzi.kamome.ApiVersionException;
import jp.hituzi.kamome.Command;
import jp.hituzi.kamome.Completion;
import jp.hituzi.kamome.Kamome;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        WebView webView = (WebView) findViewById(R.id.webView);

        try {
            Kamome kamome = Kamome.createInstanceForWebView(webView);
            kamome.addCommand(new Command("echo", new Command.IHandler() {

                @Override
                public void execute(JSONObject data, Completion completion) {
                    try {
                        completion.complete(new JSONObject().put("message", data.getString("message")));
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
            }));
        } catch (ApiVersionException e) {
            e.printStackTrace();
        }

        webView.loadUrl("file:///android_asset/www/index.html");
    }
}
