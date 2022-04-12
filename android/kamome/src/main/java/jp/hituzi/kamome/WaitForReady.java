package jp.hituzi.kamome;

import android.os.Handler;
import android.os.Looper;

final class WaitForReady {

    public interface Executable {

        void onExecute();
    }

    private int retryCount = 0;

    public boolean wait(final Executable execute) {
        if (retryCount >= 50) {
            return false;
        }
        retryCount++;

        new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {

            @Override
            public void run() {
                execute.onExecute();
            }
        }, 200);

        return true;
    }
}
