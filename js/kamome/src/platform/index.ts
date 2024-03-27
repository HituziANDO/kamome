export interface Index {
  /**
   * Tells whether your app has the KM native client.
   *
   * @returns `true` if your app has the KM native client, `false` otherwise.
   */
  hasClient(): boolean;

  /**
   * Sends a JSON string to the KM native client.
   *
   * @param json A JSON string to send.
   */
  send(json: string): void;
}

export class AndroidPlatform implements Index {
  /**
   * Tells whether your app has the KM Android client.
   *
   * @returns `true` if your app has the KM Android client, `false` otherwise.
   */
  hasClient(): boolean {
    return navigator.userAgent.toLowerCase().indexOf('android') > 0 && 'kamomeAndroid' in window;
  }

  send(json: string): void {
    // @ts-ignore
    setTimeout(() => window.kamomeAndroid.kamomeSend(json), 0);
  }
}

export class IosPlatform implements Index {
  /**
   * Tells whether your app has the KM iOS client.
   * (Requires WKWebView.)
   *
   * @returns `true` if your app has the KM iOS client, `false` otherwise.
   */
  hasClient(): boolean {
    // @ts-ignore
    return 'webkit' in window && !!window.webkit.messageHandlers.kamomeSend;
  }

  send(json: string): void {
    // @ts-ignore
    setTimeout(() => window.webkit.messageHandlers.kamomeSend.postMessage(json), 0);
  }
}

export class FlutterPlatform implements Index {
  /**
   * Tells whether your app has the KM Flutter client.
   * Supports [webview_flutter](https://pub.dev/packages/webview_flutter) plugin and
   * [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) plugin.
   *
   * @returns `true` if your app has the KM Flutter client, `false` otherwise.
   */
  hasClient(): boolean {
    return 'kamomeFlutter' in window || 'flutter_inappwebview' in window;
  }

  send(json: string): void {
    if ('kamomeFlutter' in window) {
      // @ts-ignore
      setTimeout(() => window.kamomeFlutter.postMessage(json), 0);
    } else if ('flutter_inappwebview' in window) {
      // @ts-ignore
      setTimeout(() => window.flutter_inappwebview.callHandler('kamomeFlutter', json), 0);
    }
  }
}
