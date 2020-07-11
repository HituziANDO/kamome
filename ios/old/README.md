# Kamome for iOS (Old)
## Build SDK

1. Open Kamome.xcworkspace using Xcode
1. Run "Universal > Generic iOS Device"

## Run Sample App

1. Open Kamome.xcworkspace using Xcode
1. Build SDK before running the sample app
1. Run app
    
    **Swift** Run KamomeSwift > (Your Device)  
    **Objective-C** Run Kamome / (Your Device)

## Quick Usage

### Send a message from the JS code to the native code

1. Send a message from the JavaScript code
	
	```javascript
	// JavaScript
	
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
	// Swift
	
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

### Send a message from the native code to the JS code

1. Send a message from the native code on iOS
	
	```swift
	// Swift
	
	// Send a data to JavaScript.
	kamome.sendMessage(with: ["greeting": "Hello! by Swift"], name: "greeting") { (commandName, result, error) in
	    // Received a result from the JS code.
	    guard let result = result else { return }
	    print("result: \(result)")
	}
	```

1. Receive a message on the JavaScript code
	
	```javascript
	// JavaScript
	
	// Add a receiver that receives a message sent by the native client.
	Kamome.addReceiver('greeting', function (data, resolve, reject) {
	    // The data is the object sent by the native client.
	    console.log(data.greeting);

	    // Run asynchronous something to do...
	    setTimeout(function () {

	        // Return a result as any object or null to the native client.
	        resolve('OK!');
	        // If the task is failed, call `reject()` function.
	        //reject('Error message');
	    }, 1000);
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
