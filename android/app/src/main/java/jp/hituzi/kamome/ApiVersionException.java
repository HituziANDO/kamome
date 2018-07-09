package jp.hituzi.kamome;

public final class ApiVersionException extends Exception {

    public ApiVersionException() {
        super("Current API version is not supported by Kamome.");
    }
}
