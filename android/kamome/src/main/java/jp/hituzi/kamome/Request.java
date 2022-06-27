package jp.hituzi.kamome;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

final class Request {

    @NonNull
    final String name;
    @NonNull
    final String callbackId;
    @Nullable
    final Object data;

    public Request(@NonNull final String name,
        @NonNull final String callbackId,
        @Nullable final Object data) {
        this.name = name;
        this.callbackId = callbackId;
        this.data = data;
    }
}
