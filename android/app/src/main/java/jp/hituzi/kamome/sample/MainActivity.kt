package jp.hituzi.kamome.sample

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.util.Log
import android.webkit.WebView
import android.widget.ImageButton
import jp.hituzi.kamome.Command
import jp.hituzi.kamome.Client
import jp.hituzi.kamome.Client.SendMessageCallback
import java.util.*

class MainActivity : Activity() {

    companion object {
        private const val TAG = "KamomeSample"
    }

    private var client: Client? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        actionBar?.hide()

        val webView = findViewById<WebView>(R.id.webView)

        // Creates the Client object with the webView.
        client = Client(webView)
            .add(Command("echo") { commandName, data, completion ->
                // Received `echo` command.
                // Then sends resolved result to the JavaScript callback function.
                val map = HashMap<String?, Any?>()
                map["message"] = data!!.optString("message")
                completion.resolve(map)
            })
            .add(Command("echoError") { commandName, data, completion ->
                // Sends rejected result if failed.
                completion.reject("Echo Error!")
            })
            .add(Command("tooLong") { commandName, data, completion ->
                // Too long process...
                Handler().postDelayed({ completion.resolve() }, (30 * 1000).toLong())
            })

        client?.howToHandleNonExistentCommand = Client.HowToHandleNonExistentCommand.REJECTED

        webView.loadUrl("file:///android_asset/www/index.html")

        val sendButton = findViewById<ImageButton>(R.id.sendButton)
        sendButton.setOnClickListener {
            // Sends a data to the JS code.
            val data = HashMap<String?, Any?>()
            data["greeting"] = "Hello! by Kotlin"
            client?.send(data, "greeting", SendMessageCallback { commandName, result, error ->
                // Received a result from the JS code.
                Log.d(TAG, "result: $result")
            })
        }
    }
}
