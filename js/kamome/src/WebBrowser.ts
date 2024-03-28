import { KM } from './KM';
import { KamomeEventData } from './KamomeEventData';
import { KamomeEventResult } from './KamomeEventResult';
import { KamomeRequest } from './KamomeRequest';
import { undefinedToNull } from './util/undefinedToNull';
import { uuid } from './util/uuid';

export type CommandHandlerResolve = (data?: KamomeEventResult | null) => void;
export type CommandHandlerReject = (reason: string | null) => void;
export type CommandHandler = (
  data: KamomeEventData | null,
  resolve: CommandHandlerResolve,
  reject: CommandHandlerReject,
) => void;

export class WebBrowser {
  constructor(private handlerDict: { [name: string]: CommandHandler } = {}) {}

  /**
   * Adds a command when it will be processed in the browser not the WebView.
   * The handler format is following.
   *
   *  ```javascript
   *  function (data, resolve, reject) {
   *      // Something to do.
   *      // If succeeded
   *      // resolve(response);   // response is any object or null
   *      // Else
   *      // reject('Error Message');
   *  }
   *  ```
   *
   * @param name A command name.
   * @param handler A handler.
   * @returns This instance.
   */
  addCommand(name: string, handler: CommandHandler): WebBrowser {
    this.handlerDict[name] = handler;
    return this;
  }

  /**
   * Removes a command of specified name.
   *
   * @param name A command name that you will remove.
   * @returns This instance.
   */
  removeCommand(name: string): WebBrowser {
    if (this.hasCommand(name)) {
      delete this.handlerDict[name];
    }
    return this;
  }

  /**
   * Tells whether specified command is registered.
   *
   * @param name A command name.
   * @returns `true` if the command is registered, `false` otherwise.
   */
  hasCommand(name: string): boolean {
    return name in this.handlerDict;
  }

  /**
   * Sends a message to the receiver added by `KM.addReceiver` method.
   *
   * @param name A command name.
   * @param data A JSON data.
   * @returns A promise object.
   */
  send(name: string, data?: KamomeEventData | null): Promise<KamomeEventResult> {
    return new Promise<KamomeEventResult>((resolve, reject) => {
      const callbackId = `_km_${name}_${uuid()}`;

      // Add a temporary command.
      this.addCommand(callbackId, (aResult, cmdResolve, _) => {
        const result: { success: boolean; result?: any; error?: string } = aResult;
        if (result) {
          if (result['success']) {
            resolve(result['result']);
          } else {
            const reason = result['error'] || 'UnknownError';
            reject(reason);
          }
        } else {
          reject('UnknownError');
        }

        cmdResolve();

        // Remove the temporary command.
        this.removeCommand(callbackId);
      });

      // Sends a message to the receiver added by `KM.addReceiver` method.
      KM.onReceive(name, data, callbackId);
    });
  }

  /**
   * Executes a command with specified request.
   *
   * @param req A request object.
   */
  execCommand(req: KamomeRequest) {
    setTimeout(() => {
      const resolve: CommandHandlerResolve = data => {
        const result = undefinedToNull<KamomeEventResult>(data);
        KM.onComplete(result, req.id);
      };
      const reject: CommandHandlerReject = reason => {
        KM.onError(reason ? encodeURIComponent(reason) : null, req.id);
      };
      this.handlerDict[req.name](undefinedToNull<KamomeEventData>(req.data), resolve, reject);
    }, 0);
  }
}
