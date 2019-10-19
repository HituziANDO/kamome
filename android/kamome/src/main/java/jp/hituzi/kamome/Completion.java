package jp.hituzi.kamome;

import android.support.annotation.Nullable;
import android.webkit.WebView;

import org.json.JSONArray;
import org.json.JSONObject;

import jp.hituzi.kamome.internal.Messenger;

public final class Completion {

    private final WebView webView;
    private final String requestId;
    private boolean completed;

    Completion(WebView webView, String requestId) {
        this.webView = webView;
        this.requestId = requestId;
    }

    public boolean isCompleted() {
        return completed;
    }

    @Deprecated
    public void complete() {
        resolve();
    }

    @Deprecated
    public void complete(@Nullable JSONObject data) {
        resolve(data);
    }

    @Deprecated
    public void complete(@Nullable JSONArray data) {
        resolve(data);
    }

    public void resolve() {
        resolve((JSONObject) null);
    }

    public void resolve(@Nullable JSONObject data) {
        if (completed) {
            return;
        }

        completed = true;

        Messenger.completeMessage(webView, data, requestId);
    }

    public void resolve(@Nullable JSONArray data) {
        if (completed) {
            return;
        }

        completed = true;

        Messenger.completeMessage(webView, data, requestId);
    }

    public void reject() {
        reject(null);
    }

    public void reject(@Nullable String errorMessage) {
        if (completed) {
            return;
        }

        completed = true;

        Messenger.failMessage(webView, errorMessage, requestId);
    }
}
