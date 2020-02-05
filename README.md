# kamome

Kamome is a library for iOS and Android apps using the WebView. This library bridges a gap between JavaScript in the WebView and the native code written by Swift, Objective-C, Java or Kotlin.

<img src="./README/images/illustration.png" width="410">

Kamome provides common JavaScript interface for iOS and Android.

## Quick Usage

### Send a message from the JS code to the native code

1. Send a message from the JavaScript code
	
	```javascript
	// Send `echo` command.
	Kamome.send('echo', { message: 'Hello' }).then(function (result) {
	    // Receive a result from the native code if succeeded.
	    console.log(data.message);
	}).catch(function (error) {
	    // Receive an error from the native code if failed.
	    console.log(error);
	});
	```

1. Receive a message on iOS
	
	```swift
	private var webView: WKWebView!
	private var kamome: KMMKamome!

	override func viewDidLoad() {
	    super.viewDidLoad()

	    // Create the Kamome object with default webView.
	    var webView: AnyObject!
	    kamome = KMMKamome.create(webView: &webView, class: WKWebView.self, frame: view.frame)
	    self.webView = webView as? WKWebView

	    // Register `echo` command.
	    kamome.add(KMMCommand(name: "echo") { commandName, data, completion in
	              // Received `echo` command.
	              // Then send resolved result to the JavaScript callback function.
	              completion.resolve(with: ["message": data!["message"]!])
	              // Or, send rejected result if failed.
	              //completion.reject(with: "Echo Error!")
	          })

	    let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www")!
	    self.webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
	    view.addSubview(self.webView)
	}
	```

	**[NOTE]** This framework supports WKWebView only. UIWebView not supported.
	
1. Receive a message on Android
	
	```java
	private Kamome kamome;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
	    super.onCreate(savedInstanceState);
	    setContentView(R.layout.activity_main);

	    WebView webView = findViewById(R.id.webView);

	    // Create the Kamome object with the webView.
	    kamome = new Kamome(webView)
	        .add(new Command("echo", new Command.IHandler() {  // Register `echo` command.

	            @Override
	            public void execute(String commandName, JSONObject data, ICompletion completion) {
	                try {
	                    // Received `echo` command.
	                    // Then send resolved result to the JavaScript callback function.
	                    completion.resolve(new JSONObject().put("message", data.getString("message")));
	                    // Or, send rejected result if failed.
	                    //completion.reject("Echo Error!");
	                } catch (JSONException e) {}
	            }
	        }));

	    webView.loadUrl("file:///android_asset/www/index.html");
	}
	```

### Send a message from the native code to the JS code

1. Send a message from the native code on iOS
	
	```swift
	// Send a data to JavaScript.
	kamome.sendMessage(with: ["greeting": "Hello! by Swift"], name: "greeting") { result in
	    // Received a result from the JS code.
	    guard let result = result else { return }
	    print("result: \(result)")
	}
	```

1. Send a message from the native code on Android
	
	```java
	try {
	    // Send a data to JavaScript.
	    kamome.sendMessage(new JSONObject().put("greeting", "Hello! by Java"),
	        "greeting",
	        new Kamome.IResultCallback() {
	
	            @Override
	            public void onReceiveResult(Object result) {
	                // Received a result from the JS code.
	                Log.d(TAG, "result: " + result);
	            }
	        });
	} catch (JSONException e) {}
	```

1. Receive a message on the JavaScript code
	
	```javascript
	// Add a receiver that receives a message sent by the native client.
	Kamome.addReceiver('greeting', function (data) {
	    console.log(data.greeting);
	
	    // Return a result to the native client.
	    return 'OK!'; // Any object or null.
	});
	```

## Include Library in Your Project

### 1. JavaScript

1. Download latest [Kamome SDK](https://github.com/HituziANDO/kamome/releases)

1. Import kamome.js or kamome.min.js
	
	```html
	<script src="/path/to/kamome[.min].js"></script>
	```
	
	Or, you copy all code in [kamome.js](https://github.com/HituziANDO/kamome/blob/master/js/src/kamome.js) file to your JavaScript.
	
### 2. iOS App

#### CocoaPods
	
Kamome is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:
	
```ruby
pod "KamomeSDK"
```

#### Manual Installation

Drag & drop KamomeSDK.framework into your Xcode project

#### Import Framework

Write the import statement in your source code

```swift
import KamomeSDK
```

### 3. Android App

#### Gradle

Add the following code in build.gradle(project level).

```groovy
allprojects {
    repositories {
        maven {
            url 'https://hituziando.github.io/kamome/android/repo'
        }
    }
}
```

Add the following code in build.gradle(app level).

```groovy
dependencies {		
    implementation 'jp.hituzi:kamome:2.0.2'
}
```

#### Manual Installation
	
1. Copy kamome-x.x.x.jar to YOUR_ANDROID_STUDIO_PROJECT/app/libs directory
1. Sync Project in AndroidStudio

## Configuration

### Timeout to request from the JS code to the native code

`Kamome.send` method in JavaScript expects a `resolve` or `reject` response will be returned in a duration. If the request is timed out, it's the callback calls `reject` with the `requestTimeout` error. You can change default request timeout. See following.

```javascript
// Set default timeout in millisecond.
Kamome.setDefaultRequestTimeout(15000);
```

If given time is less than or equal to 0, the request timeout function is disabled.

If you want to specify a request timeout individually, you set a timeout in millisecond at `Kamome.send` method's 4th argument.

```javascript
// Set a timeout in millisecond at 4th argument.
const promise = Kamome.send(commandName, data, null, 5000);
```

## Hook

Hook the command before calling it, and after processing it.

```javascript
// Hook.
Kamome.hook
    .before("getScore", function () {
        // Called before sending "getScore" command.
        Kamome.send("getUser").then(function (data) {
            console.log("Name: " + data.name);
        });
    })
    .after("getScore", function () {
        // Called after "getScore" command is processed.
        Kamome.send("getAvg").then(function (data) {
            console.log("Avg: " + data.avg);
        });
    });

// Send "getScore" command.
Kamome.send("getScore").then(function (data) {
    console.log("Score: " + data.score + " Rank: " + data.rank);
});
```

## Browser Only

When there is no Kamome's iOS/Android native client, that is, when you run with a browser alone, you can register the processing of each command.

```javascript
Kamome.browser
    .addCommand("echo", function (data, resolve, reject) {
        // Received `echo` command.
        // Then send resolved result to the JavaScript callback function.
        resolve({ message: data["message"] });
        // Or, send rejected result if failed.
        //reject("Echo Error!");
    });
```

---

More info, see my [iOS sample project](https://github.com/HituziANDO/kamome/tree/master/ios) and [Android sample project](https://github.com/HituziANDO/kamome/tree/master/android).
