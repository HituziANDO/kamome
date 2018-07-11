package jp.hituzi.kamome;

import android.annotation.SuppressLint;
import android.os.Build;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

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

    @JavascriptInterface
    public void kamomeSend(String message) {
        try {
            JSONObject object = new JSONObject(message);
            String name = object.getString("name");
            JSONObject data = object.isNull("data") ? null : object.getJSONObject("data");

            for (Command command : commands) {
                if (name.equals(command.getName())) {
                    command.execute(data, new Completion(webView, command.getName()));
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}
