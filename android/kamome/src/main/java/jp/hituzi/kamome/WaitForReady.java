package jp.hituzi.kamome;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

final class WaitForReady {
    public interface Executable {
        void onExecute();
    }

    private int retryCount = 0;

    public boolean wait(@NonNull final Executable execute) {
        if (retryCount >= 50) {
            return false;
        }
        retryCount++;

        new Handler(Looper.getMainLooper()).postDelayed(execute::onExecute, 200);

        return true;
    }
}
