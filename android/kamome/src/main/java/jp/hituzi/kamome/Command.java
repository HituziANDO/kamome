package jp.hituzi.kamome;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.json.JSONObject;

public final class Command {
    public interface Handler {
        void execute(@NonNull String commandName, @Nullable JSONObject data, @NonNull Completable completion);
    }

    @NonNull
    private final String name;
    @Nullable
    private final Handler handler;

    public Command(@NonNull final String name, @Nullable final Handler handler) {
        this.name = name;
        this.handler = handler;
    }

    @NonNull
    public String getName() {
        return name;
    }

    void execute(@Nullable final JSONObject data, @NonNull final Completable completion) {
        if (handler != null) {
            handler.execute(name, data, completion);
        }
    }
}
