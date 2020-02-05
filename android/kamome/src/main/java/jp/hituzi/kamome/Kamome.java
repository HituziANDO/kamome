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

import jp.hituzi.kamome.exception.ApiVersionException;
import jp.hituzi.kamome.exception.CommandNotAddedException;
import jp.hituzi.kamome.internal.Messenger;

public final class Kamome {

    public enum HowToHandleNonExistentCommand {
        /**
         * Anyway resolved passing null.
         */
        RESOLVED,
        /**
         * Always rejected and passing an error message.
         */
        REJECTED,
        /**
         * Always raises an exception.
         */
        EXCEPTION
    }

    public interface IResultCallback {

        /**
         * Receives a result from the JavaScript receiver when it processed a task of a command.
         *
         * @param result A result.
         */
        void onReceiveResult(@Nullable Object result);
    }

    /**
     * How to handle non-existent command.
     */
    public HowToHandleNonExistentCommand howToHandleNonExistentCommand = HowToHandleNonExistentCommand.RESOLVED;

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
            Messenger.sendMessage(webView, name, data, null, null);
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
            Messenger.sendMessage(webView, name, data, null, null);
        }
    }

    /**
     * Executes a command to the native receiver.
     *
     * @param name     A command name.
     * @param callback A callback.
     */
    public void executeCommand(String name, @Nullable LocalCompletion.ICallback callback) {
        executeCommand(name, null, callback);
    }

    /**
     * Executes a command with data to the native receiver.
     *
     * @param name     A command name.
     * @param data     A data as NSDictionary.
     * @param callback A callback.
     */
    public void executeCommand(String name, @Nullable JSONObject data, @Nullable LocalCompletion.ICallback callback) {
        handleCommand(name, data, new LocalCompletion(callback));
    }

    /**
     * [NOTE] This method should not be executed directly.
     *
     * @param message A JSON passed from the JavaScript object.
     */
    @JavascriptInterface
    public void kamomeSend(String message) {
        try {
            JSONObject object = new JSONObject(message);
            String requestId = object.getString("id");
            String name = object.getString("name");
            JSONObject data = object.isNull("data") ? null : object.getJSONObject("data");
            handleCommand(name, data, new Completion(webView, requestId));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void handleCommand(String name, @Nullable JSONObject data, ICompletion completion) {
        Command command = commands.get(name);

        if (command != null) {
            command.execute(data, completion);
        } else {
            switch (howToHandleNonExistentCommand) {
                case REJECTED:
                    completion.reject("CommandNotAdded");
                    break;
                case EXCEPTION:
                    throw new CommandNotAddedException(name);
                default:
                    completion.resolve();
            }
        }
    }
}
