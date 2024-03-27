import { KamomeError } from './KamomeError.ts';
import { KamomeEventData } from './KamomeEventData.ts';
import { KamomeEventResult } from './KamomeEventResult.ts';
import { KamomeRequest } from './KamomeRequest.ts';
import { VERSION_CODE } from './VERSION_CODE.ts';
import { WebBrowser } from './WebBrowser.ts';
import { AndroidPlatform, FlutterPlatform, IosPlatform } from './platform';
import { undefinedToNull } from './util/undefinedToNull.ts';
import { uuid } from './util/uuid.ts';

/**
 * The ready event listener.
 */
export type OnReadyListener = () => void;
/**
 * Receiver function.
 */
export type OnReceiver = (
  data: KamomeEventData | null,
  resolve: (data?: KamomeEventResult | null) => void,
  reject: (reason?: string) => void,
) => void;

const COMMAND_SYN: string = '_kamomeSYN';
const COMMAND_ACK: string = '_kamomeACK';

const android = new AndroidPlatform();
const iOS = new IosPlatform();
const flutter = new FlutterPlatform();
const browser = new WebBrowser();

let isReady = false;
let retryCountForReady = 0;
let onReady: OnReadyListener | null = null;

export class KM {
  /**
   * The constructor.
   *
   * @param receivers The receiver dictionary.
   * @param requests The request dictionary.
   * @param requestTimeout Default value is 10 seconds.
   * @private
   */
  private constructor(
    private receivers: { [commandName: string]: OnReceiver } = {},
    private requests: { [id: string]: KamomeRequest } = {},
    private requestTimeout = 10000,
  ) {}

  private static instance = new KM();

  static get VERSION_CODE() {
    return VERSION_CODE;
  }

  static get Error() {
    return KamomeError;
  }

  static get android() {
    return android;
  }

  static get iOS() {
    return iOS;
  }

  static get flutter() {
    return flutter;
  }

  static get browser() {
    return browser;
  }

  /**
   * Tells whether the native client is ready.
   *
   * @returns `true` if the native client is ready, otherwise `false`.
   */
  static isReady() {
    return isReady;
  }

  /**
   * Sets a ready event listener.
   * The listener is called when Kamome iOS, Android, or Flutter client goes ready state.
   *
   * @param listener A listener. If `null` is passed, the listener is removed.
   * @returns This instance.
   */
  static setReadyEventListener(listener: OnReadyListener | null): KM {
    onReady = listener;
    return this.instance;
  }

  /**
   * `KM.send` method expects a 'resolve'/'reject' response will be returned in a duration.
   * If the request is timed out, it's callback calls `reject` with requestTimeout error.
   * You can change default request timeout.
   * Sets a timeout for a request. If given `time` <= 0, the request timeout function is disabled.
   *
   * @param timeMillis Timeout in millisecond.
   * @returns This instance.
   */
  static setDefaultRequestTimeout(timeMillis: number): KM {
    this.instance.requestTimeout = timeMillis;
    return this.instance;
  }

  /**
   * Tells whether the Kamome native client is not present.
   *
   * @returns `true` if the Kamome native client is not present, otherwise `false`.
   */
  static hasNoClients() {
    return !iOS.hasClient() && !android.hasClient() && !flutter.hasClient();
  }

  /**
   * Registers a receiver for given command. The receiver function receives a JSON message from the native.
   *
   * @param {string} name A command name.
   * @param {Function} receiver A receiver is following.
   *
   *  ```javascript
   *  function(json, resolve, reject) {
   *      // Something to do.
   *      // If succeeded
   *      // resolve(response);   // response is any object or null
   *      // Else
   *      // reject('Error Message');
   *  }
   *  ```
   *
   *  @returns This instance.
   */
  static addReceiver(name: string, receiver: OnReceiver): KM {
    this.instance.receivers[name] = receiver;
    return this.instance;
  }

  /**
   * Removes a receiver for given command if it is registered.
   *
   * @param name A command name.
   * @returns This instance.
   */
  static removeReceiver(name: string): KM {
    if (name in this.instance.receivers) {
      delete this.instance.receivers[name];
    }
    return this.instance;
  }

  /**
   * Sends a JSON message to the native.
   *
   * @param name A command name.
   * @param data A data.
   * @param timeoutMillis Timeout in milliseconds for this request. If this argument is omitted or null, default timeout is used.
   * @returns A promise object.
   */
  static send(
    name: string,
    data?: KamomeEventData | null,
    timeoutMillis?: number | null,
  ): Promise<KamomeEventResult | null> {
    const timeout = timeoutMillis || this.instance.requestTimeout;

    return new Promise<KamomeEventResult | null>((resolve, reject) => {
      const id = uuid();
      const req: KamomeRequest = {
        id,
        name,
        data,
        timeout,
        resolve,
        reject,
      };
      this.instance.requests[id] = req;

      if (name === COMMAND_SYN || name === COMMAND_ACK) {
        // Send initialization commands to ready.
        this.sendRequest(req);
      } else {
        this.waitForReadyAndSendRequests();
      }
    });
  }

  private static sendRequest(req: KamomeRequest) {
    const data = undefinedToNull<KamomeEventData>(req.data);
    const json = JSON.stringify({ name: req.name, data, id: req.id });

    if (iOS.hasClient()) {
      iOS.send(json);
    } else if (android.hasClient()) {
      android.send(json);
    } else if (flutter.hasClient()) {
      flutter.send(json);
    } else if (browser.hasCommand(req.name)) {
      browser.execCommand(req);
    }

    if (req.timeout > 0) {
      // Set the request timeout.
      setTimeout(() => {
        const timedOutReq = this.instance.requests[req.id];
        if (timedOutReq) {
          timedOutReq.reject(KamomeError.requestTimeout + ':' + timedOutReq.name);
          delete this.instance.requests[timedOutReq.id];
        }
      }, req.timeout);
    }
  }

  private static waitForReadyAndSendRequests() {
    // Waiting for ready.
    if (!isReady) {
      if (retryCountForReady < 50) {
        retryCountForReady++;
        setTimeout(this.waitForReadyAndSendRequests, 200);
      } else {
        console.error('[kamome.js] Waiting for ready has timed out.');
      }
      return;
    }

    for (const id in this.instance.requests) {
      const req = this.instance.requests[id];
      this.sendRequest(req);
    }
  }

  /**
   * Called from the native client when sent message is processed successfully.
   *
   * @param result A JSON object passed from the native client, or null.
   * @param requestId A request ID.
   * @returns null
   */
  static onComplete(result: KamomeEventResult | null, requestId: string) {
    const req = this.instance.requests[requestId];
    if (req) {
      req.resolve(result);
      delete this.instance.requests[requestId];
    }
    return null;
  }

  /**
   * Called from the native client when sent message is processed incorrectly.
   *
   * @param errorMessage An error message passed from the native client, or null.
   * @param requestId A request ID.
   * @returns null
   */
  static onError(errorMessage: string | null, requestId: string) {
    const req = this.instance.requests[requestId];
    if (req) {
      const msg = errorMessage ? ':' + decodeURIComponent(errorMessage) : '';
      req.reject(KamomeError.rejected + ':' + req.name + msg);
      delete this.instance.requests[requestId];
    }
    return null;
  }

  /**
   * Receives a message from the native client.
   *
   * @param name A command name.
   * @param data A JSON object passed from the native client, or null.
   * @param callbackId A callback ID.
   * @returns null
   */
  static onReceive(name: string, data: KamomeEventData | null, callbackId: string) {
    if (name in this.instance.receivers) {
      new Promise<KamomeEventResult | null>((resolve, reject) => {
        const fn = this.instance.receivers[name];
        // Process a message from the native client.
        fn(data, resolve, reject);
      })
        // If succeeded, sends a result to the native.
        .then(result => this.send(callbackId, { result: result || null, success: true }))
        // If failed, sends an error message as string type to the native.
        .catch(error => this.send(callbackId, { error: error || null, success: false }));
    }
    return null;
  }
}

// Add preset commands.
browser.addCommand(COMMAND_SYN, (_, resolve) => resolve({ versionCode: VERSION_CODE }));
browser.addCommand(COMMAND_ACK, (_, resolve) => resolve());

function ready() {
  KM.send(COMMAND_SYN, null, 5000)
    .then(data => {
      if (VERSION_CODE !== data.versionCode) {
        console.warn(
          '[kamome.js] The Kamome native library version does not match. Please update it to latest version.',
        );
      }

      isReady = true;

      setTimeout(() => onReady?.(), 0);

      KM.send(COMMAND_ACK, null, 5000).catch(() => console.warn('[kamome.js] Failed to send ACK.'));
    })
    .catch(() => {
      console.warn(
        '[kamome.js] Failed to send SYN. Please update the Kamome native library to latest version.',
      );
      // Set true for backward compatibility. (< 5.1.0)
      isReady = true;
    });
}

// Side effect: Add the ready event listener.
if ('flutter_inappwebview' in window) {
  window.addEventListener('flutterInAppWebViewPlatformReady', ready);
} else {
  window.addEventListener('DOMContentLoaded', ready);
}

// Side effect: For backward compatibility. (< 5.3.0)
// @ts-ignore
window.KM = KM;
