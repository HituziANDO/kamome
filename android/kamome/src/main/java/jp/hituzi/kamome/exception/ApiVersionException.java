package jp.hituzi.kamome.exception;

public final class ApiVersionException extends Exception {

    public ApiVersionException() {
        super("Current API version is not supported by Kamome.");
    }
}
