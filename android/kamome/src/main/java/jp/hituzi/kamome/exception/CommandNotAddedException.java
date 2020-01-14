package jp.hituzi.kamome.exception;

public final class CommandNotAddedException extends RuntimeException {

    public CommandNotAddedException(String commandName) {
        super(commandName + " command not added.");
    }
}
