package jp.hituzi.kamome;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Collection;
import java.util.Map;

public final class LocalCompletion implements Completable {
    public interface Callback {
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
        void onRejected(@NonNull String errorMessage);
    }

    @NonNull
    private final Callback callback;
    private boolean completed;

    LocalCompletion(@NonNull final Callback callback) {
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
    public void resolve(@Nullable final Map data) {
        if (data == null) {
            resolve((JSONObject) null);
        } else {
            try {
                resolve(new JSONObject(data));
            } catch (Exception e) {
                reject("Failed to create JSONObject.");
            }
        }
    }

    @Override
    public void resolve(@Nullable final JSONObject data) {
        if (completed) {
            return;
        }

        completed = true;

        callback.onResolved(data);
    }

    @Override
    public void resolve(@Nullable final Collection data) {
        resolve(new JSONArray(data));
    }

    @Override
    public void resolve(@Nullable final JSONArray data) {
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
    public void reject(@Nullable final String errorMessage) {
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
