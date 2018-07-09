package jp.hituzi.kamome;

import org.json.JSONObject;

public final class Command {

    public interface IHandler {

        void execute(JSONObject data, Completion completion);
    }

    private String name;
    private IHandler handler;

    public Command(String name, IHandler handler) {
        this.name = name;
        this.handler = handler;
    }

    public String getName() {
        return name;
    }

    void execute(JSONObject data, Completion completion) {
        if (handler != null) {
            handler.execute(data, completion);
        }
    }
}
