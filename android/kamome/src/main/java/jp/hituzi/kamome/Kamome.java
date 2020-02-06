package jp.hituzi.kamome;

import android.annotation.SuppressLint;
import android.os.Build;
import android.support.annotation.Nullable;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Collection;
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

    public interface ISendMessageCallback {

        /**
         * Receives a result from the JavaScript receiver when it processed a task of a command.
         *
         * @param commandName A command name.
         * @param result      A result when the native client receives it successfully from the JavaScript receiver.
         * @param error       An error when the native client receives it from the JavaScript receiver. If a task in JavaScript results in successful, the error will be null.
         */
        void onReceiveResult(String commandName, @Nullable Object result, @Nullable Error error);
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
    public void sendMessage(String name, @Nullable ISendMessageCallback callback) {
        sendMessage((JSONObject) null, name, callback);
    }

    /**
     * Sends a message with data as Map to the JavaScript receiver.
     *
     * @param data     A data as Map.
     * @param name     A command name.
     * @param callback A callback.
     */
    public void sendMessage(Map data, String name, @Nullable ISendMessageCallback callback) {
        sendMessage(new JSONObject(data), name, callback);
    }

    /**
     * Sends a message with data as JSONObject to the JavaScript receiver.
     *
     * @param data     A data as JSONObject.
     * @param name     A command name.
     * @param callback A callback.
     */
    public void sendMessage(JSONObject data, String name, @Nullable ISendMessageCallback callback) {
        if (callback != null) {
            String callbackId = addSendMessageCallback(callback);
            Messenger.sendMessage(webView, name, data, callbackId);
        } else {
            Messenger.sendMessage(webView, name, data, null);
        }
    }

    /**
     * Sends a message with data as Collection to the JavaScript receiver.
     *
     * @param data     A data as Collection.
     * @param name     A command name.
     * @param callback A callback.
     */
    public void sendMessage(Collection data, String name, @Nullable ISendMessageCallback callback) {
        sendMessage(new JSONArray(data), name, callback);
    }

    /**
     * Sends a message with data as JSONArray to the JavaScript receiver.
     *
     * @param data     A data as JSONArray.
     * @param name     A command name.
     * @param callback A callback.
     */
    public void sendMessage(JSONArray data, String name, @Nullable ISendMessageCallback callback) {
        if (callback != null) {
            String callbackId = addSendMessageCallback(callback);
            Messenger.sendMessage(webView, name, data, callbackId);
        } else {
            Messenger.sendMessage(webView, name, data, null);
        }
    }

    /**
     * Executes a command to the native receiver.
     *
     * @param name     A command name.
     * @param callback A callback.
     */
    public void executeCommand(String name, @Nullable LocalCompletion.ICallback callback) {
        executeCommand(name, (JSONObject) null, callback);
    }

    /**
     * Executes a command with data to the native receiver.
     *
     * @param name     A command name.
     * @param data     A data as Map.
     * @param callback A callback.
     */
    public void executeCommand(String name, @Nullable Map data, @Nullable LocalCompletion.ICallback callback) {
        handleCommand(name, data != null ? new JSONObject(data) : null, new LocalCompletion(callback));
    }

    /**
     * Executes a command with data to the native receiver.
     *
     * @param name     A command name.
     * @param data     A data as JSONObject.
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

    private String addSendMessageCallback(final ISendMessageCallback callback) {
        final String callbackId = UUID.randomUUID().toString();

        // Add a temporary command receiving a result from the JavaScript handler.
        add(new Command(callbackId, new Command.IHandler() {

            @Override
            public void execute(String commandName, @Nullable JSONObject data, ICompletion completion) {
                assert data != null;
                boolean success = data.optBoolean("success");

                if (success) {
                    callback.onReceiveResult(commandName, data.opt("result"), null);
                } else {
                    String errorMessage = data.optString("error");
                    Error error = new Error(errorMessage != null && !errorMessage.isEmpty() ? errorMessage : "UnknownError");
                    callback.onReceiveResult(commandName, null, error);
                }

                completion.resolve();

                // Remove the temporary command.
                removeCommand(callbackId);
            }
        }));

        return callbackId;
    }
}
