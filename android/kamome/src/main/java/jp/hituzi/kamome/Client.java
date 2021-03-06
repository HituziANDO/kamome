package jp.hituzi.kamome;

import android.annotation.SuppressLint;
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

import jp.hituzi.kamome.exception.CommandNotAddedException;
import jp.hituzi.kamome.internal.Messenger;

public final class Client {

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

    public interface SendMessageCallback {

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

    @SuppressLint("SetJavaScriptEnabled")
    public Client(WebView webView) {
        this.webView = webView;
        webView.getSettings().setJavaScriptEnabled(true);
        webView.addJavascriptInterface(this, "kamomeAndroid");
    }

    /**
     * Adds a command called by the JavaScript code.
     *
     * @param command A command.
     * @return Self.
     */
    public Client add(Command command) {
        commands.put(command.getName(), command);
        return this;
    }

    /**
     * Removes a command of specified name.
     *
     * @param commandName A command name that you will remove.
     */
    public void remove(String commandName) {
        if (hasCommand(commandName)) {
            commands.remove(commandName);
        }
    }

    /**
     * Tells whether specified command is added.
     *
     * @param name A command name.
     * @return true if the command of specified name is added, otherwise false.
     */
    public boolean hasCommand(String name) {
        return commands.containsKey(name);
    }

    /**
     * Sends a message to the JavaScript receiver.
     *
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(String commandName, @Nullable SendMessageCallback callback) {
        send((JSONObject) null, commandName, callback);
    }

    /**
     * Sends a message with a data as Map to the JavaScript receiver.
     *
     * @param data        A data as Map.
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(@Nullable Map data, String commandName, @Nullable SendMessageCallback callback) {
        send(data != null ? new JSONObject(data) : null, commandName, callback);
    }

    /**
     * Sends a message with a data as JSONObject to the JavaScript receiver.
     *
     * @param data        A data as JSONObject.
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(@Nullable JSONObject data, String commandName, @Nullable SendMessageCallback callback) {
        if (callback != null) {
            String callbackId = addSendMessageCallback(callback);
            Messenger.sendMessage(webView, commandName, data, callbackId);
        } else {
            Messenger.sendMessage(webView, commandName, data, null);
        }
    }

    /**
     * Sends a message with a data as Collection to the JavaScript receiver.
     *
     * @param data        A data as Collection.
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(@Nullable Collection data, String commandName, @Nullable SendMessageCallback callback) {
        send(data != null ? new JSONArray(data) : null, commandName, callback);
    }

    /**
     * Sends a message with a data as JSONArray to the JavaScript receiver.
     *
     * @param data        A data as JSONArray.
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(@Nullable JSONArray data, String commandName, @Nullable SendMessageCallback callback) {
        if (callback != null) {
            String callbackId = addSendMessageCallback(callback);
            Messenger.sendMessage(webView, commandName, data, callbackId);
        } else {
            Messenger.sendMessage(webView, commandName, data, null);
        }
    }

    /**
     * Executes a command added to this client.
     *
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void execute(String commandName, @Nullable LocalCompletion.Callback callback) {
        execute(commandName, (JSONObject) null, callback);
    }

    /**
     * Executes a command added to this client with a data.
     *
     * @param commandName A command name.
     * @param data        A data as Map.
     * @param callback    A callback.
     */
    public void execute(String commandName, @Nullable Map data, @Nullable LocalCompletion.Callback callback) {
        handle(commandName, data != null ? new JSONObject(data) : null, new LocalCompletion(callback));
    }

    /**
     * Executes a command added to this client with a data.
     *
     * @param commandName A command name.
     * @param data        A data as JSONObject.
     * @param callback    A callback.
     */
    public void execute(String commandName, @Nullable JSONObject data, @Nullable LocalCompletion.Callback callback) {
        handle(commandName, data, new LocalCompletion(callback));
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
            handle(name, data, new Completion(webView, requestId));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void handle(String commandName, @Nullable JSONObject data, Completable completion) {
        Command command = commands.get(commandName);

        if (command != null) {
            command.execute(data, completion);
        } else {
            switch (howToHandleNonExistentCommand) {
                case REJECTED:
                    completion.reject("CommandNotAdded");
                    break;
                case EXCEPTION:
                    throw new CommandNotAddedException(commandName);
                default:
                    completion.resolve();
            }
        }
    }

    private String addSendMessageCallback(final SendMessageCallback callback) {
        final String callbackId = UUID.randomUUID().toString();

        // Add a temporary command receiving a result from the JavaScript handler.
        add(new Command(callbackId, new Command.Handler() {

            @Override
            public void execute(String commandName, @Nullable JSONObject data, Completable completion) {
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
                remove(callbackId);
            }
        }));

        return callbackId;
    }
}
