package jp.hituzi.kamome;

import android.webkit.WebView;

import org.json.JSONArray;
import org.json.JSONObject;

import jp.hituzi.kamome.internal.Messenger;

public final class Completion {

    private final WebView webView;
    private final String name;
    private boolean completed;

    public Completion(WebView webView, String name) {
        this.webView = webView;
        this.name = name;
    }

    public boolean isCompleted() {
        return completed;
    }

    public void complete() {
        complete((JSONObject) null);
    }

    public void complete(JSONObject data) {
        if (completed) {
            return;
        }

        completed = true;

        Messenger.completeMessage(webView, name, data);
    }

    public void complete(JSONArray data) {
        if (completed) {
            return;
        }

        completed = true;

        Messenger.completeMessage(webView, name, data);
    }
}
