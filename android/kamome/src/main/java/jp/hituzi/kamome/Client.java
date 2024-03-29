package jp.hituzi.kamome;

import android.annotation.SuppressLint;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import jp.hituzi.kamome.exception.CommandNotAddedException;

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

    public interface ReadyEventListener {
        void onReady();
    }

    public interface SendMessageCallback {
        /**
         * Receives a result from the JavaScript receiver when it processed a task of a command.
         *
         * @param commandName A command name.
         * @param result      A result when the native client receives it successfully from the JavaScript receiver.
         * @param error       An error when the native client receives it from the JavaScript receiver. If a task in JavaScript results in successful, the error will be null.
         */
        void onReceiveResult(@NonNull final String commandName, @Nullable final Object result, @Nullable final Error error);
    }

    @NonNull
    private static final String TAG = "Kamome";
    @NonNull
    private static final String COMMAND_SYN = "_kamomeSYN";
    @NonNull
    private static final String COMMAND_ACK = "_kamomeACK";

    /**
     * How to handle non-existent command.
     */
    @NonNull
    public HowToHandleNonExistentCommand howToHandleNonExistentCommand = HowToHandleNonExistentCommand.RESOLVED;
    /**
     * A ready event listener.
     * The listener is called when the Kamome JavaScript library goes ready state.
     */
    @Nullable
    public ReadyEventListener readyEventListener;

    @NonNull
    private final WebView webView;
    @NonNull
    private final Map<String, Command> commands = new HashMap<>();
    @NonNull
    private final List<Request> requests = new ArrayList<>();
    @NonNull
    private final WaitForReady waitForReady = new WaitForReady();
    private boolean ready = false;

    @SuppressLint("SetJavaScriptEnabled")
    public Client(@NonNull final WebView webView) {
        this.webView = webView;
        webView.getSettings().setJavaScriptEnabled(true);
        webView.addJavascriptInterface(this, "kamomeAndroid");

        // Add preset commands.
        add(new Command(COMMAND_SYN, (commandName, data, completion) -> {
            ready = true;

            try {
                completion.resolve(new JSONObject().put("versionCode", BuildConfig.VERSION_CODE));
            } catch (JSONException e) {
                Log.e(TAG, "Failed to resolve with versionCode json.", e);
            }
        })).add(new Command(COMMAND_ACK, (commandName, data, completion) -> {
            new Handler(Looper.getMainLooper()).post(() -> {
                if (readyEventListener != null) {
                    readyEventListener.onReady();
                }
            });

            completion.resolve();
        }));
    }

    /**
     * Tells whether the Kamome JavaScript library is ready.
     */
    public boolean isReady() {
        return ready;
    }

    /**
     * Adds a command called by the JavaScript code.
     *
     * @param command A command.
     * @return Self.
     */
    @NonNull
    public Client add(@NonNull final Command command) {
        commands.put(command.getName(), command);
        return this;
    }

    /**
     * Removes a command of specified name.
     *
     * @param commandName A command name that you will remove.
     */
    public void remove(@NonNull final String commandName) {
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
    public boolean hasCommand(@NonNull final String name) {
        return commands.containsKey(name);
    }

    /**
     * Sends a message to the JavaScript receiver.
     *
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(@NonNull final String commandName, @Nullable final SendMessageCallback callback) {
        send((JSONObject) null, commandName, callback);
    }

    /**
     * Sends a message with a data as Map to the JavaScript receiver.
     *
     * @param data        A data as Map.
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(@Nullable final Map data, @NonNull final String commandName, @Nullable final SendMessageCallback callback) {
        send(data != null ? new JSONObject(data) : null, commandName, callback);
    }

    /**
     * Sends a message with a data as JSONObject to the JavaScript receiver.
     *
     * @param data        A data as JSONObject.
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(@Nullable final JSONObject data, @NonNull final String commandName, @Nullable final SendMessageCallback callback) {
        String callbackId = addSendMessageCallback(commandName, callback);
        requests.add(new Request(commandName, callbackId, data));

        waitForReadyAndSendRequests();
    }

    /**
     * Sends a message with a data as Collection to the JavaScript receiver.
     *
     * @param data        A data as Collection.
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(@Nullable final Collection data, @NonNull final String commandName, @Nullable final SendMessageCallback callback) {
        send(data != null ? new JSONArray(data) : null, commandName, callback);
    }

    /**
     * Sends a message with a data as JSONArray to the JavaScript receiver.
     *
     * @param data        A data as JSONArray.
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void send(@Nullable final JSONArray data, @NonNull final String commandName, @Nullable final SendMessageCallback callback) {
        String callbackId = addSendMessageCallback(commandName, callback);
        requests.add(new Request(commandName, callbackId, data));

        waitForReadyAndSendRequests();
    }

    /**
     * Executes a command added to this client.
     *
     * @param commandName A command name.
     * @param callback    A callback.
     */
    public void execute(@NonNull final String commandName, @Nullable final LocalCompletion.Callback callback) {
        execute(commandName, (JSONObject) null, callback);
    }

    /**
     * Executes a command added to this client with a data.
     *
     * @param commandName A command name.
     * @param data        A data as Map.
     * @param callback    A callback.
     */
    public void execute(@NonNull final String commandName, @Nullable final Map data, @Nullable final LocalCompletion.Callback callback) {
        handle(commandName, data != null ? new JSONObject(data) : null, new LocalCompletion(callback));
    }

    /**
     * Executes a command added to this client with a data.
     *
     * @param commandName A command name.
     * @param data        A data as JSONObject.
     * @param callback    A callback.
     */
    public void execute(@NonNull final String commandName, @Nullable final JSONObject data, @Nullable final LocalCompletion.Callback callback) {
        handle(commandName, data, new LocalCompletion(callback));
    }

    /**
     * [NOTE] This method should not be executed directly.
     *
     * @param message A JSON passed from the JavaScript object.
     */
    @JavascriptInterface
    public void kamomeSend(@NonNull final String message) {
        try {
            JSONObject object = new JSONObject(message);
            String requestId = object.getString("id");
            String name = object.getString("name");
            JSONObject data = object.isNull("data") ? null : object.getJSONObject("data");
            handle(name, data, new Completion(webView, requestId));
        } catch (JSONException e) {
            Log.e(TAG, "Failed to parse JSON.", e);
        }
    }

    private void handle(@NonNull final String commandName, @Nullable final JSONObject data, @NonNull final Completable completion) {
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

    @NonNull
    private String addSendMessageCallback(@NonNull final String commandName, @Nullable final SendMessageCallback callback) {
        final String callbackId = "_km_" + commandName + "_" + UUID.randomUUID().toString();

        // Add a temporary command receiving a result from the JavaScript handler.
        add(new Command(callbackId, (commandName1, data, completion) -> {
            assert data != null;
            boolean success = data.optBoolean("success");

            if (success) {
                if (callback != null) {
                    callback.onReceiveResult(commandName1, data.opt("result"), null);
                }
            } else {
                String errorMessage = data.optString("error");
                Error error = new Error(!errorMessage.isEmpty() ? errorMessage : "UnknownError");

                if (callback != null) {
                    callback.onReceiveResult(commandName1, null, error);
                }
            }

            completion.resolve();

            // Remove the temporary command.
            remove(callbackId);
        }));

        return callbackId;
    }

    /**
     * Waits for ready. If ready, sends requests to the JS library.
     */
    private void waitForReadyAndSendRequests() {
        if (!ready) {
            boolean isWaiting = waitForReady.wait(this::waitForReadyAndSendRequests);

            if (!isWaiting) {
                Log.d(TAG, "Waiting for ready has timed out.");
            }

            return;
        }

        for (Request request : requests) {
            Messenger.sendRequest(webView, request);
        }

        // Reset
        requests.clear();
    }
}
