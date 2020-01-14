package jp.hituzi.kamome;

import android.support.annotation.Nullable;

import org.json.JSONArray;
import org.json.JSONObject;

public final class LocalCompletion implements ICompletion {

    public interface ICallback {

        /**
         * Calls when a command is processed successfully.
         *
         * @param result A result as JSONObject or JSONArray.
         */
        void onResolved(@Nullable Object result);

        /**
         * Calls when a command is processed incorrectly.
         *
         * @param errorMessage An error message.
         */
        void onRejected(String errorMessage);
    }

    private final ICallback callback;
    private boolean completed;

    LocalCompletion(ICallback callback) {
        this.callback = callback;
    }

    @Override
    public boolean isCompleted() {
        return completed;
    }

    @Override
    public void resolve() {
        resolve((JSONObject) null);
    }

    @Override
    public void resolve(@Nullable JSONObject data) {
        if (completed) {
            return;
        }

        completed = true;

        callback.onResolved(data);
    }

    @Override
    public void resolve(@Nullable JSONArray data) {
        if (completed) {
            return;
        }

        completed = true;

        callback.onResolved(data);
    }

    @Override
    public void reject() {
        reject(null);
    }

    @Override
    public void reject(@Nullable String errorMessage) {
        if (completed) {
            return;
        }

        completed = true;

        if (errorMessage != null && !errorMessage.isEmpty()) {
            callback.onRejected(errorMessage);
        } else {
            callback.onRejected("Rejected");
        }
    }
}
