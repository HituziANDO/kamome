# kamome

***kamome is iOS/Android library sending messages between JavaScript and native code written by Objective-C or Java in the WebView.***

## Include in your app

1. Download latest [kamome SDK](https://github.com/HituziANDO/kamome/releases)

1. Import kamome.min.js
	
	```html
	<script src="kamome.min.js"></script>
	```

1. Import KamomeSDK.framework to your iOS app
	
	### Manual Installation
	
	1. Drag & Drop KamomeSDK.framework into your Xcode project
	1. Write `#import <KamomeSDK/KamomeSDK.h>` in your source code

1. Import kamome-x.x.x.jar to your Android app
	
	### Manual Installation
	
	1. Copy kamome-x.x.x.jar to `YOUR_ANDROID_STUDIO_PROJECT/app/libs` directory
	1. Sync Project in AndroidStudio

## Usage

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
	KMMKamome *kamome = [KMMKamome new];
	
	WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
	configuration.userContentController = kamome.userContentController;
	self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
	
	[kamome setWebView:self.webView];
	
	// Register `echo` command
	[kamome addCommand:[KMMCommand commandWithName:@"echo" handler:^(NSDictionary *data, KMMCompletion *completion) {
	    // Receive `echo` command
	    
	    // Then send result to JavaScript callback function
	    [completion completeWithDictionary:@{ @"message": data[@"message"] }];
	}]];
	```
	
1. Receive message on Android
	
	```java
	WebView webView = (WebView) findViewById(R.id.webView);
	
	try {
	    Kamome kamome = Kamome.createInstanceForWebView(webView);
	    
	    // Register `echo` command
	    kamome.addCommand(new Command("echo", new Command.IHandler() {
	        
	        @Override
	        public void execute(JSONObject data, Completion completion) {
	            // Receive `echo` message
	            
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

More info, see my [iOS sample project](https://github.com/HituziANDO/kamome/tree/master/ios) and [Android sample project](https://github.com/HituziANDO/kamome/tree/master/android).
