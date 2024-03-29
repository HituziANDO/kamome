package jp.hituzi.kamome;

import android.webkit.WebView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Collection;
import java.util.Map;

public final class Completion implements Completable {
    @NonNull
    private final WebView webView;
    @NonNull
    private final String requestId;
    private boolean completed;

    Completion(@NonNull final WebView webView, @NonNull final String requestId) {
        this.webView = webView;
        this.requestId = requestId;
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

        Messenger.completeMessage(webView, data, requestId);
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

        Messenger.completeMessage(webView, data, requestId);
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

        Messenger.failMessage(webView, errorMessage, requestId);
    }
}
