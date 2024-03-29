package jp.hituzi.kamome.exception;

import androidx.annotation.NonNull;

public final class CommandNotAddedException extends RuntimeException {
    public CommandNotAddedException(@NonNull final String commandName) {
        super(commandName + " command not added.");
    }
}
