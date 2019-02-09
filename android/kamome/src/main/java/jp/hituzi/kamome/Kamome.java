package jp.hituzi.kamome;

import android.annotation.SuppressLint;
import android.os.Build;
import android.support.annotation.Nullable;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import jp.hituzi.kamome.internal.Messenger;

public final class Kamome {

    public interface IResultCallback {

        void onReceiveResult(@Nullable Object result);
    }

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

    public void sendMessage(String name, @Nullable final IResultCallback callback) {
        sendMessage((JSONObject) null, name, callback);
    }

    public void sendMessage(JSONObject data, String name, @Nullable final IResultCallback callback) {
        if (callback != null) {
            Messenger.sendMessage(webView, name, data, new Messenger.IMessageCallback() {

                @Override
                public void onReceiveResult(Object result) {
                    callback.onReceiveResult(result);
                }
            }, UUID.randomUUID().toString());
        } else {
            Messenger.sendMessage(webView, name, null, null, null);
        }
    }

    public void sendMessage(JSONArray data, String name, @Nullable final IResultCallback callback) {
        if (callback != null) {
            Messenger.sendMessage(webView, name, data, new Messenger.IMessageCallback() {

                @Override
                public void onReceiveResult(Object result) {
                    callback.onReceiveResult(result);
                }
            }, UUID.randomUUID().toString());
        } else {
            Messenger.sendMessage(webView, name, null, null, null);
        }
    }

    /**
     * [NOTE] This method should not be executed directly.
     *
     * @param message A JSON passed from JavaScript.
     */
    @JavascriptInterface
    public void kamomeSend(String message) {
        try {
            JSONObject object = new JSONObject(message);
            String requestId = object.getString("id");
            String name = object.getString("name");
            JSONObject data = object.isNull("data") ? null : object.getJSONObject("data");

            Command command = null;

            for (Command cmd : commands) {
                if (name.equals(cmd.getName())) {
                    command = cmd;
                    break;
                }
            }

            Completion completion = new Completion(webView, requestId);

            if (command != null) {
                command.execute(data, completion);
            } else {
                completion.resolve();
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}
