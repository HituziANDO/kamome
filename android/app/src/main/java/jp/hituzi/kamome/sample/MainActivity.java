package jp.hituzi.kamome.sample;

import android.app.ActionBar;
import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.webkit.WebView;
import android.widget.Button;

import org.json.JSONException;
import org.json.JSONObject;

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

        ActionBar actionBar = getActionBar();
        if (actionBar != null) {
            actionBar.hide();
        }

        WebView webView = findViewById(R.id.webView);

        kamome = new Kamome(webView)
            .add(new Command("echo", new Command.IHandler() {

                @Override
                public void execute(String commandName, JSONObject data, Completion completion) {
                    try {
                        // Success
                        completion.resolve(new JSONObject().put("message", data.getString("message")));
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
            }))
            .add(new Command("echoError", new Command.IHandler() {

                @Override
                public void execute(String commandName, JSONObject data, Completion completion) {
                    // Failure
                    completion.reject("Echo Error!");
                }
            }))
            .add(new Command("tooLong", new Command.IHandler() {

                @Override
                public void execute(String commandName, JSONObject data, final Completion completion) {
                    // Too long process
                    new Handler().postDelayed(new Runnable() {

                        @Override
                        public void run() {
                            completion.resolve();
                        }
                    }, 30 * 1000);
                }
            }));

        webView.loadUrl("file:///android_asset/www/index.html");

        Button sendButton = findViewById(R.id.sendButton);
        sendButton.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View view) {
                try {
                    // Send data to JavaScript.
                    kamome.sendMessage(new JSONObject().put("greeting", "Hello! by Java"),
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
