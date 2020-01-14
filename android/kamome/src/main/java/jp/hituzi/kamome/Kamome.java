package jp.hituzi.kamome;

import android.annotation.SuppressLint;
import android.os.Build;
import android.support.annotation.Nullable;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import jp.hituzi.kamome.internal.Messenger;

public final class Kamome {

    public interface IResultCallback {

        void onReceiveResult(@Nullable Object result);
    }

    private final WebView webView;
    private final Map<String, Command> commands = new HashMap<>();

    @Deprecated
    @SuppressLint("SetJavaScriptEnabled")
    public static Kamome createInstanceForWebView(WebView webView) throws ApiVersionException {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR1) {
            throw new ApiVersionException();
        }

        return new Kamome(webView);
    }

    @SuppressLint("SetJavaScriptEnabled")
    public Kamome(WebView webView) {
        this.webView = webView;
        webView.getSettings().setJavaScriptEnabled(true);
        webView.addJavascriptInterface(this, "kamomeAndroid");
    }

    /**
     * Adds a command called by JavaScript code.
     *
     * @param command A command.
     * @return Self.
     */
    public Kamome add(Command command) {
        commands.put(command.getName(), command);
        return this;
    }

    /**
     * Removes a command of specified name.
     *
     * @param name A command name that you will remove.
     */
    public void removeCommand(String name) {
        commands.remove(name);
    }

    /**
     * Sends a message to the JavaScript receiver.
     *
     * @param name     A command name.
     * @param callback A callback.
     */
    public void sendMessage(String name, @Nullable final IResultCallback callback) {
        sendMessage((JSONObject) null, name, callback);
    }

    /**
     * Sends a message with data as JSONObject to the JavaScript receiver.
     *
     * @param data     A data as JSONObject.
     * @param name     A command name.
     * @param callback A callback.
     */
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

    /**
     * Sends a message with data as JSONArray to the JavaScript receiver.
     *
     * @param data     A data as JSONArray.
     * @param name     A command name.
     * @param callback A callback.
     */
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
            Command command = commands.get(name);
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
