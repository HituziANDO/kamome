package jp.hituzi.kamome;

import android.annotation.SuppressLint;
import android.os.Build;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import jp.hituzi.kamome.internal.Messenger;

public final class Kamome {

    private final WebView webView;
    private final List<Command> commands = new ArrayList<>();

    @SuppressLint("SetJavaScriptEnabled")
    public static Kamome createInstanceForWebView(WebView webView) throws ApiVersionException {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR1) {
            throw new ApiVersionException();
        }

        Kamome kamome = new Kamome(webView);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.addJavascriptInterface(kamome, "kamomeAndroid");

        return kamome;
    }

    private Kamome(WebView webView) {
        this.webView = webView;
    }

    public Kamome addCommand(Command command) {
        commands.add(command);
        return this;
    }

    public void sendMessage(JSONObject data, String name) {
        Messenger.sendMessage(webView, name, data);
    }

    public void sendMessage(JSONArray data, String name) {
        Messenger.sendMessage(webView, name, data);
    }

    @JavascriptInterface
    public void kamomeSend(String message) {
        try {
            JSONObject object = new JSONObject(message);
            String name = object.getString("name");
            JSONObject data = object.isNull("data") ? null : object.getJSONObject("data");

            Command command = null;

            for (Command cmd : commands) {
                if (name.equals(cmd.getName())) {
                    command = cmd;
                    break;
                }
            }

            Completion completion = new Completion(webView, name);

            if (command != null) {
                command.execute(data, completion);
            } else {
                completion.complete();
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}
