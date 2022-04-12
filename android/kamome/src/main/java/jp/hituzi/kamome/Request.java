package jp.hituzi.kamome;

import android.support.annotation.Nullable;

final class Request {

    final String name;
    @Nullable
    final String callbackId;
    @Nullable
    final Object data;

    public Request(final String name,
        @Nullable final String callbackId,
        @Nullable final Object data) {
        this.name = name;
        this.callbackId = callbackId;
        this.data = data;
    }
}
