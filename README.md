# kamome

***Kamome is iOS/Android library sending messages between JavaScript and native code written by Objective-C or Java in the WebView.***

<img src="./README/images/illustration.png" width="410">

Kamome provides common JavaScript interface for iOS and Android.

## Include in your app

1. Download latest [kamome SDK](https://github.com/HituziANDO/kamome/releases)

1. Import kamome.min.js
	
	```html
	<script src="kamome.min.js"></script>
	```
	
	Or copy the code in [kamome[.min].js](https://github.com/HituziANDO/kamome/blob/master/js/src/kamome.js) to your JavaScript.

1. Import KamomeSDK.framework to your iOS app
	
	### Manual Installation
	
	1. Drag & Drop KamomeSDK.framework into your Xcode project
	1. Write `#import <KamomeSDK/KamomeSDK.h>` in your source code

1. Import kamome-x.x.x.jar to your Android app
	
	### Manual Installation
	
	1. Copy kamome-x.x.x.jar to `YOUR_ANDROID_STUDIO_PROJECT/app/libs` directory
	1. Sync Project in AndroidStudio

## Usage

### JavaScript to Native Code

1. Send message from JavaScript and then receive callback
	
	```javascript
	// Send `echo` command
	Kamome.send('echo', { message: 'Hello' }, function (data) {
	    // Callback from native
	    console.log(data.message);
	});
	```
	
	Or return Promise
	
	```javascript
	Kamome.send('echo', { message: 'Hello' }).then(function (data) {
	    // Callback from native
	    console.log(data.message);
	});
	```

1. Receive message on iOS
	
	```objc
	@property (nonatomic) KMMKamome *kamome;
	```
	
	```objc
	self.kamome = [KMMKamome new];
	
	WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
	configuration.userContentController = self.kamome.userContentController;
	self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
	
	[self.kamome setWebView:self.webView];
	
	// Register `echo` command
	[self.kamome addCommand:[KMMCommand commandWithName:@"echo" handler:^(NSDictionary *data, KMMCompletion *completion) {
	    // Receive `echo` command
	    
	    // Then send result to JavaScript callback function
	    [completion completeWithDictionary:@{ @"message": data[@"message"] }];
	}]];
	```
	
	**[NOTE]** Supports WKWebView only. UIWebView not supported.
	
1. Receive message on Android
	
	```java
	// Instance variable
	private Kamome kamome;
	```
	
	```java
	WebView webView = (WebView) findViewById(R.id.webView);
	
	try {
	    kamome = Kamome.createInstanceForWebView(webView);
	    
	    // Register `echo` command
	    kamome.addCommand(new Command("echo", new Command.IHandler() {
	        
	        @Override
	        public void execute(JSONObject data, Completion completion) {
	            // Receive `echo` command
	            
	            try {
	                // Then send result to JavaScript callback function
	                completion.complete(new JSONObject().put("message", data.getString("message")));
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

1. Send message from native code and then receive callback

	**iOS**
	
	```objc
	[self.kamome sendMessageWithDictionary:@{ @"greeting": @"Hello!" }
                                     block:^(id result) {
                                         NSLog(@"result: %@", result);	// => 'World!'
                                     }
                                   forName:@"greeting"];
	```
	
	**Android**
	
	```java
	try {
	    // Send data to JavaScript.
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
	
1. Receive message on JavaScript
	
	```javascript
	Kamome.addReceiver('greeting', function (data) {
	    console.log(data.greeting);	// => 'Hello!'
	    
	    // Return result to native code.
	    return 'World!';	// Any object or null.
	});
	```

More info, see my [iOS sample project](https://github.com/HituziANDO/kamome/tree/master/ios) and [Android sample project](https://github.com/HituziANDO/kamome/tree/master/android).
