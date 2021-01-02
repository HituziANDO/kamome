package jp.hituzi.kamome;

import android.support.annotation.Nullable;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Collection;
import java.util.Map;

public interface Completable {

    boolean isCompleted();

    /**
     * Sends resolved result to a JavaScript callback function.
     */
    void resolve();

    /**
     * Sends resolved result with a data to a JavaScript callback function.
     *
     * @param data A data as Map.
     */
    void resolve(@Nullable Map data);

    /**
     * Sends resolved result with a data to a JavaScript callback function.
     *
     * @param data A data as JSONObject.
     */
    void resolve(@Nullable JSONObject data);

    /**
     * Sends resolved result with a data to a JavaScript callback function.
     *
     * @param data A data as Collection.
     */
    void resolve(@Nullable Collection data);

    /**
     * Sends resolved result with a data to a JavaScript callback function.
     *
     * @param data A data as JSONArray.
     */
    void resolve(@Nullable JSONArray data);

    /**
     * Sends rejected result to a JavaScript callback function.
     */
    void reject();

    /**
     * Sends rejected result with an error message to a JavaScript callback function.
     *
     * @param errorMessage An error message.
     */
    void reject(@Nullable String errorMessage);
}
