# Kamome

Kamome is a library for iOS and Android apps using the WebView. This library bridges a gap between JavaScript in the WebView and the native code written in Swift, Java or Kotlin.

<img src="./README/images/illustration.png" width="410">

Kamome provides common JavaScript interface for iOS and Android.

## Quick Usage

### Sends a message from the JS code to the native code

1. Sends a message from the JavaScript code
	
	```javascript
	// JavaScript

	import {KM} from "kamome"

	// Uses async/await.
	try {
	    // Sends `echo` command.
	    const result = await KM.send('echo', { message: 'Hello' });
	    // Receives a result from the native code if succeeded.
	    console.log(result.message);
	} catch(error) {
	    // Receives an error from the native code if failed.
	    console.log(error);
	}
	```

1. Receives a message on iOS
	
	```swift
	// Swift

	private lazy var webView: WKWebView = {
	    let webView = WKWebView(frame: self.view.frame)
	    return webView
	}()

	private var client: Client!

	override func viewDidLoad() {
	    super.viewDidLoad()

	    // Creates the Client object with the webView.
	    client = Client(webView)

	    // Registers `echo` command.
	    client.add(Command("echo") { commandName, data, completion in
	        // Received `echo` command.
	        // Then sends resolved result to the JavaScript callback function.
	        completion.resolve(["message": data!["message"]!])
	        // Or, sends rejected result if failed.
	        //completion.reject("Echo Error!")
	    })

	    let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www")!
	    webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
	    view.addSubview(webView)
	}
	```

	**[NOTE]** This framework supports WKWebView only. UIWebView is not supported.
	
1. Receives a message on Android
	
	```kotlin
	// Kotlin

	private var client: Client? = null

	override fun onCreate(savedInstanceState: Bundle?) {
       super.onCreate(savedInstanceState)
       setContentView(R.layout.activity_main)

       val webView = findViewById<WebView>(R.id.webView)

       // Creates the Client object with the webView.
       client = Client(webView)

       // Registers `echo` command.
       client.add(Command("echo") { commandName, data, completion ->
           // Received `echo` command.
           // Then sends resolved result to the JavaScript callback function.
           val map = HashMap<String?, Any?>()
           map["message"] = data!!.optString("message")
           completion.resolve(map)
           // Or, sends rejected result if failed.
           //completion.reject("Echo Error!")
       })

       webView.loadUrl("file:///android_asset/www/index.html")
   }
	```

### Sends a message from the native code to the JS code

1. Sends a message from the native code on iOS
	
	```swift
	// Swift
	
	// Send a data to the JS code.
	client.send(["greeting": "Hello! by Swift"], commandName: "greeting") { (commandName, result, error) in
	    // Received a result from the JS code.
	    guard let result = result else { return }
	    print("result: \(result)")
	}
	```

1. Sends a message from the native code on Android
	
	```kotlin
	// Kotlin
	
	// Sends a data to the JS code.
	val data = HashMap<String?, Any?>()
   data["greeting"] = "Hello! by Kotlin"
   client?.send(data, "greeting") { commandName, result, error ->
       // Received a result from the JS code.
       Log.d(TAG, "result: $result")
   }
	```

1. Receives a message on the JavaScript code
	
	```javascript
	// JavaScript
	
	// Adds a receiver that receives a message sent by the native client.
	KM.addReceiver('greeting', (data, resolve, reject) => {
	    // The data is the object sent by the native client.
	    console.log(data.greeting);

	    // Runs asynchronous something to do...
	    setTimeout(() => {

	        // Returns a result as any object or null to the native client.
	        resolve('OK!');
	        // If the task is failed, call `reject()` function.
	        //reject('Error message');
	    }, 1000);
	});
	```

## Include Library in Your Project

### 1. JavaScript

#### npm

1. npm install
	
	```
	npm install kamome
	```

1. Write following import statement in JavaScript
	
	```javascript
	import {KM} from "kamome"
	```
	
#### Manual Installation

1. Download latest [Kamome SDK](https://github.com/HituziANDO/kamome/releases)

1. Import kamome.js or kamome.min.js
	
	```html
	<script src="/path/to/kamome[.min].js"></script>
	```
	
	Or, you copy all code in [kamome.js](https://github.com/HituziANDO/kamome/blob/master/js/kamome/src/lib/kamome.js) file to your JavaScript.
	
1. (Optional) TypeScript
	
	If you install kamome.js manually and use TypeScript, you download [kamome.d.ts](https://github.com/HituziANDO/kamome/tree/master/js/kamome/src/kamome.d.ts) file and import it in your project's directory such as `@types`.

### 2. iOS App

#### CocoaPods
	
Kamome is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:
	
```ruby
pod "kamome"
```

#### Carthage

Kamome is available through [Carthage](https://github.com/Carthage/Carthage). To install it, simply add the following line to your Cartfile:

```
github "HituziANDO/kamome"
```

#### Swift Package Manager

Kamome is available through Swift Package Manager. To install it using Xcode, see following.

1. Click "File" menu.
1. Select "Swift Packages".
1. Click "Add Package Dependency...".
1. Specify the git URL for kamome.
	
```
https://github.com/HituziANDO/kamome.git
```

#### Manual Installation

1. Drag & drop kamome.xcframework into your Xcode project
1. Click General tab in your target
1. In Frameworks, Libraries, and Embedded Content, Select "Embed & Sign" for kamome.xcframework

#### Import Framework

Write the import statement in your source code

```swift
import kamome
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
    implementation 'jp.hituzi:kamome:5.0.0'
}
```

#### Manual Installation
	
1. Copy kamome-x.x.x.jar to YOUR_ANDROID_STUDIO_PROJECT/app/libs directory
1. Sync Project in AndroidStudio

## Configuration

### Timeout to request from the JS code to the native code

`KM.send` method in JavaScript expects a `resolve` or `reject` response will be returned in a duration. If the request is timed out, it's the callback calls `reject` with the `requestTimeout` error. You can change default request timeout. See following.

```javascript
// JavaScript

// Set default timeout in millisecond.
KM.setDefaultRequestTimeout(15000);
```

If given time is less than or equal to 0, the request timeout function is disabled.

If you want to specify a request timeout individually, you set a timeout in millisecond at `KM.send` method's 3rd argument.

```javascript
// JavaScript

// Set a timeout in millisecond at 3rd argument.
const promise = KM.send(commandName, data, 5000);
```

## Optional: console.log for iOS

The `ConsoleLogAdapter` class enables to output logs by `console.log`, `console.warn`, and `console.error` in JavaScript to Xcode console.

```swift
// Swift

ConsoleLogAdapter().setTo(webView)
```

## Browser Alone

When there is no Kamome's iOS/Android native client, that is, when you run with a browser alone, you can register the processing of each command.

```javascript
// JavaScript

KM.browser
    .addCommand("echo", function (data, resolve, reject) {
        // Received `echo` command.
        // Then sends resolved result to the JavaScript callback function.
        resolve({ message: data["message"] });
        // Or, sends rejected result if failed.
        //reject("Echo Error!");
    });
```

---

More info, see my [iOS sample project](https://github.com/HituziANDO/kamome/tree/master/ios) and [Android sample project](https://github.com/HituziANDO/kamome/tree/master/android).
