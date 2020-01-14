package jp.hituzi.kamome;

import android.support.annotation.Nullable;

import org.json.JSONObject;

public final class Command {

    public interface IHandler {

        void execute(String commandName, @Nullable JSONObject data, Completion completion);
    }

    private String name;
    @Nullable
    private IHandler handler;

    public Command(String name, @Nullable IHandler handler) {
        this.name = name;
        this.handler = handler;
    }

    public String getName() {
        return name;
    }

    void execute(@Nullable JSONObject data, Completion completion) {
        if (handler != null) {
            handler.execute(name, data, completion);
        }
    }
}
