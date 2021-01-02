package jp.hituzi.kamome;

import android.support.annotation.Nullable;

import org.json.JSONObject;

public final class Command {

    public interface Handler {

        void execute(String commandName, @Nullable JSONObject data, Completable completion);
    }

    private String name;
    @Nullable
    private Handler handler;

    public Command(String name, @Nullable Handler handler) {
        this.name = name;
        this.handler = handler;
    }

    public String getName() {
        return name;
    }

    void execute(@Nullable JSONObject data, Completable completion) {
        if (handler != null) {
            handler.execute(name, data, completion);
        }
    }
}
