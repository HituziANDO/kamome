# kamome

***Kamome is iOS/Android library sending messages between JavaScript and native code written by Objective-C or Java in the WebView.***

<img src="./README/images/illustration.png" width="410">

Kamome provides common JavaScript interface for iOS and Android.

## Include in your app

1. Downloads latest [kamome SDK](https://github.com/HituziANDO/kamome/releases)

1. Imports kamome.min.js
	
	```html
	<script src="kamome.min.js"></script>
	```
	
	Or copies the code in [kamome[.min].js](https://github.com/HituziANDO/kamome/blob/master/js/src/kamome.js) to your JavaScript.

1. Imports KamomeSDK.framework to your iOS app
	
	### CocoaPods
	
	Kamome is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:
	
	```ruby
	pod "KamomeSDK"
	```
	
	### Manual Installation
	
	1. Drags & Drops KamomeSDK.framework into your Xcode project
	1. Writes `#import <KamomeSDK/KamomeSDK.h>` in your source code

1. Imports kamome-x.x.x.jar to your Android app
	
	### Gradle
	
	Adds the following code in build.gradle(project level).
	
	```groovy
	allprojects {
		repositories {
			
			maven {
				url 'https://hituziando.github.io/kamome/android/repo'
			}
		}
	}
	```
	
	Adds the following code in build.gradle(app level).
	
	```groovy
	dependencies {
		
		implementation 'jp.hituzi:kamome:1.4.0'
	}
	```
	
	### Manual Installation
	
	1. Copies kamome-x.x.x.jar to `YOUR_ANDROID_STUDIO_PROJECT/app/libs` directory
	1. Sync Project in AndroidStudio

## Usage

### JavaScript to Native Code

1. Sends a message from JavaScript and then receives callback
	
	```javascript
	// Sends `echo` command
	Kamome.send('echo', { message: 'Hello' }, function (data, error) {
	    if (!error) {
	        // Callback from the native if succeeded
	        console.log(data.message);
	    } else {
	        // Callback from the native if failed
	        console.log(error);
	    }
	});
	```
	
	Or returns Promise
	
	```javascript
	Kamome.send('echo', { message: 'Hello' }).then(function (data) {
	    // Callback from the native if succeeded
	    console.log(data.message);
	}).catch(function (error) {
	    // Callback from the native if failed
	    console.log(error);
	});
	```

1. Receives a message on iOS
	
	**Swift**

	```swift
	// Properties
	private var webView: WKWebView?
	private var kamome:  KMMKamome?
	```
	
	```swift
	// Creates a kamome instance with default webView
	var webView: WKWebView? = nil
	kamome = KMMKamome.createInstanceAndWebView(&webView, withFrame: view.frame)
	self.webView = webView
	
	// Registers `echo` command
	kamome?.add(KMMCommand(name: "echo") { data, completion in
	           // Receives `echo` command
	           
	           // Then sends resolved result to the JavaScript callback function
	           completion.resolve(with: ["message": data!["message"]!])
	           // Or sends rejected result if failed
	           //completion.reject(with: "Error message")
	       })
	
	// Adds the webView to a ViewController's view
	view.addSubview(self.webView!)
	```
	
	**Objective-C**
	
	```objc
	@property (nonatomic) KMMKamome *kamome;
	@property (nonatomic) WKWebView *webView;
	```
	
	```objc
	// Creates a kamome instance with default webView
    WKWebView *webView = nil;
    self.kamome = [KMMKamome createInstanceAndWebView:&webView withFrame:self.view.frame];
    self.webView = webView;
	
	// Registers `echo` command
	[self.kamome addCommand:[KMMCommand commandWithName:@"echo" handler:^(NSDictionary *data, KMMCompletion *completion) {
	    // Receives `echo` command
	    
	    // Then sends resolved result to the JavaScript callback function
	    [completion resolveWithDictionary:@{ @"message": data[@"message"] }];
	    // Or sends rejected result if failed
	    //[completion rejectWithErrorMessage:@"Error message"];
	}]];
	
	// Adds the webView to a ViewController's view
	[self.view addSubview:self.webView];
	```
	
	**[NOTE]** Supports WKWebView only. UIWebView not supported.
	
1. Receives a message on Android
	
	```java
	// Instance variable
	private Kamome kamome;
	```
	
	```java
	WebView webView = (WebView) findViewById(R.id.webView);
	
	try {
	    kamome = Kamome.createInstanceForWebView(webView);
	    
	    // Registers `echo` command
	    kamome.addCommand(new Command("echo", new Command.IHandler() {
	        
	        @Override
	        public void execute(JSONObject data, Completion completion) {
	            // Receives `echo` command
	            
	            try {
	                // Then sends resolved result to the JavaScript callback function
	                completion.resolve(new JSONObject().put("message", data.getString("message")));
	                // Or sends rejected result if failed
	                //completion.reject("Error message");
	            } catch (JSONException e) {
	                e.printStackTrace();
	            }
	        }
	    }));
	} catch (ApiVersionException e) {
	    e.printStackTrace();
	}
	```

### Native Code to JavaScript

1. Sends a message from native code and then receives callback

	#### iOS
	
	**Swift**
	
	```swift
	// Sends data to JavaScript
	kamome?.sendMessage(with: ["greeting": "Hello!"], block: { result in
	    guard let result = result else { return }
	    print("result: \(result)")    // => 'World!'
	}, forName: "greeting")
	```
	
	**Objective-C**
	
	```objc
	// Sends data to JavaScript
	[self.kamome sendMessageWithDictionary:@{ @"greeting": @"Hello!" }
                                     block:^(id result) {
                                         NSLog(@"result: %@", result);	// => 'World!'
                                     }
                                   forName:@"greeting"];
	```
	
	#### Android
	
	```java
	try {
	    // Sends a data to JavaScript
	    kamome.sendMessage(new JSONObject().put("greeting", "Hello!"),
	        "greeting",
	        new Kamome.IResultCallback() {
	            
	            @Override
	            public void onReceiveResult(Object result) {
	                Log.d(TAG, "result: " + result);	// => 'World!'
	            }
	        });
	} catch (JSONException e) {
	    e.printStackTrace();
	}
	```
	
1. Receives a message on JavaScript
	
	```javascript
	Kamome.addReceiver('greeting', function (data) {
	    console.log(data.greeting);	// => 'Hello!'
	    
	    // Returns a result to the native code.
	    return 'World!';	// Any object or null.
	});
	```

More info, see my [iOS sample project](https://github.com/HituziANDO/kamome/tree/master/ios) and [Android sample project](https://github.com/HituziANDO/kamome/tree/master/android).
