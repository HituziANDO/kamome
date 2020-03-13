package jp.hituzi.kamome.sample;

import android.app.ActionBar;
import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.webkit.WebView;
import android.widget.Button;

import org.json.JSONObject;

import java.util.HashMap;

import jp.hituzi.kamome.Command;
import jp.hituzi.kamome.ICompletion;
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
                public void execute(String commandName, JSONObject data, ICompletion completion) {
                    // Received `echo` command.
                    // Then send resolved result to the JavaScript callback function.
                    HashMap<String, Object> map = new HashMap<>();
                    map.put("message", data.optString("message"));
                    completion.resolve(map);
                }
            }))
            .add(new Command("echoError", new Command.IHandler() {

                @Override
                public void execute(String commandName, JSONObject data, ICompletion completion) {
                    // Send rejected result if failed.
                    completion.reject("Echo Error!");
                }
            }))
            .add(new Command("tooLong", new Command.IHandler() {

                @Override
                public void execute(String commandName, JSONObject data, final ICompletion completion) {
                    // Too long process...
                    new Handler().postDelayed(new Runnable() {

                        @Override
                        public void run() {
                            completion.resolve();
                        }
                    }, 30 * 1000);
                }
            }))
            .add(new Command("getUser", new Command.IHandler() {

                @Override
                public void execute(String commandName, JSONObject data, ICompletion completion) {
                    HashMap<String, Object> map = new HashMap<>();
                    map.put("name", "Brad");
                    completion.resolve(map);
                }
            }))
            .add(new Command("getScore", new Command.IHandler() {

                @Override
                public void execute(String commandName, JSONObject data, ICompletion completion) {
                    HashMap<String, Object> map = new HashMap<>();
                    map.put("score", 90);
                    map.put("rank", 2);
                    completion.resolve(map);
                }
            }))
            .add(new Command("getAvg", new Command.IHandler() {

                @Override
                public void execute(String commandName, JSONObject data, ICompletion completion) {
                    HashMap<String, Object> map = new HashMap<>();
                    map.put("avg", 68);
                    completion.resolve(map);
                }
            }));

        kamome.howToHandleNonExistentCommand = Kamome.HowToHandleNonExistentCommand.REJECTED;

        webView.loadUrl("file:///android_asset/www/index.html");

        Button sendButton = findViewById(R.id.sendButton);
        sendButton.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View view) {
                // Send a data to JavaScript.
                HashMap<String, Object> data = new HashMap<>();
                data.put("greeting", "Hello! by Java");
                kamome.sendMessage(data, "greeting", new Kamome.ISendMessageCallback() {

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
