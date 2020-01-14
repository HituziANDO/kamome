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

    /**
     * Sends resolved result to a JavaScript callback function.
     */
    public void resolve() {
        resolve((JSONObject) null);
    }

    /**
     * Sends resolved result with a data to a JavaScript callback function.
     *
     * @param data A data as JSONObject.
     */
    public void resolve(@Nullable JSONObject data) {
        if (completed) {
            return;
        }

        completed = true;

        Messenger.completeMessage(webView, data, requestId);
    }

    /**
     * Sends resolved result with a data to a JavaScript callback function.
     *
     * @param data A data as JSONArray.
     */
    public void resolve(@Nullable JSONArray data) {
        if (completed) {
            return;
        }

        completed = true;

        Messenger.completeMessage(webView, data, requestId);
    }

    /**
     * Sends rejected result to a JavaScript callback function.
     */
    public void reject() {
        reject(null);
    }

    /**
     * Sends rejected result with an error message to a JavaScript callback function.
     *
     * @param errorMessage An error message.
     */
    public void reject(@Nullable String errorMessage) {
        if (completed) {
            return;
        }

        completed = true;

        Messenger.failMessage(webView, errorMessage, requestId);
    }
}
