package jp.hituzi.kamome.sample;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.webkit.WebView;
import android.widget.ImageButton;

import org.json.JSONException;
import org.json.JSONObject;

import jp.hituzi.kamome.ApiVersionException;
import jp.hituzi.kamome.Command;
import jp.hituzi.kamome.Completion;
import jp.hituzi.kamome.Kamome;

public class MainActivity extends Activity {

    private static final String TAG = "KamomeSample";

    private Kamome kamome;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        WebView webView = (WebView) findViewById(R.id.webView);

        try {
            kamome = Kamome.createInstanceForWebView(webView);
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

        ImageButton sendButton = (ImageButton) findViewById(R.id.sendButton);
        sendButton.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View view) {
                try {
                    // Send data to JavaScript.
                    kamome.sendMessage(new JSONObject().put("greeting", "Hello!"),
                        "greeting",
                        new Kamome.IResultCallback() {

                            @Override
                            public void onReceiveResult(Object result) {
                                Log.d(TAG, "result: " + result);
                            }
                        });
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });
    }
}
