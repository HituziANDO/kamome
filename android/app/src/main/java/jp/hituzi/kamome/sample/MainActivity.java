package jp.hituzi.kamome.sample;

import android.app.ActionBar;
import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.webkit.WebView;
import android.widget.ImageButton;

import org.json.JSONObject;

import java.util.HashMap;

import jp.hituzi.kamome.Command;
import jp.hituzi.kamome.Completable;
import jp.hituzi.kamome.NativeClient;

public class MainActivity extends Activity {

    private static final String TAG = "KamomeSample";

    private NativeClient client;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        ActionBar actionBar = getActionBar();
        if (actionBar != null) {
            actionBar.hide();
        }

        WebView webView = findViewById(R.id.webView);

        // Creates the NativeClient object with the webView.
        client = new NativeClient(webView)
            .add(new Command("echo", new Command.Handler() {

                @Override
                public void execute(String commandName, JSONObject data, Completable completion) {
                    // Received `echo` command.
                    // Then sends resolved result to the JavaScript callback function.
                    HashMap<String, Object> map = new HashMap<>();
                    map.put("message", data.optString("message"));
                    completion.resolve(map);
                }
            }))
            .add(new Command("echoError", new Command.Handler() {

                @Override
                public void execute(String commandName, JSONObject data, Completable completion) {
                    // Sends rejected result if failed.
                    completion.reject("Echo Error!");
                }
            }))
            .add(new Command("tooLong", new Command.Handler() {

                @Override
                public void execute(String commandName, JSONObject data, final Completable completion) {
                    // Too long process...
                    new android.os.Handler().postDelayed(new Runnable() {

                        @Override
                        public void run() {
                            completion.resolve();
                        }
                    }, 30 * 1000);
                }
            }));

        client.howToHandleNonExistentCommand = NativeClient.HowToHandleNonExistentCommand.REJECTED;

        webView.loadUrl("file:///android_asset/www/index.html");

        ImageButton sendButton = findViewById(R.id.sendButton);
        sendButton.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View view) {
                // Sends a data to the JS code.
                HashMap<String, Object> data = new HashMap<>();
                data.put("greeting", "Hello! by Java");
                client.send(data, "greeting", new NativeClient.SendMessageCallback() {

                    @Override
                    public void onReceiveResult(String commandName, Object result, Error error) {
                        // Received a result from the JS code.
                        Log.d(TAG, "result: " + result);
                    }
                });
            }
        });
    }
}
