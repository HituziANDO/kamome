declare module "kamome" {
    export type CommandHandler = (data: any | null, resolve: Function, reject: Function) => void;

    export interface Error {
        requestTimeout: string;
        rejected: string;
        canceled: string;
    }

    export interface Client {
        /**
         * Tells whether your app has the Kamome client.
         *
         * @return true if the app has the Kamome client. Otherwise false.
         */
        hasClient(): boolean;
    }

    export interface Browser {
        /**
         * Adds a command when it will be processed in the browser not the WebView.
         * The handler format is following.
         *
         *  ```
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
         * @return Self.
         */
        addCommand(name: string, handler: CommandHandler): Browser;
    }

    export interface Kamome {
        Error: Error;
        android: Client;
        iOS: Client;
        browser: Browser;

        /**
         * `KM.send` method expects a 'resolve'/'reject' response will be returned in a duration.
         * If the request is timed out, it's callback calls `reject` with requestTimeout error.
         * You can change default request timeout.
         * Sets a timeout for a request. If given `time` <= 0, the request timeout function is disabled.
         *
         * @param time A time in millisecond.
         * @return Self.
         */
        setDefaultRequestTimeout(time: number): Kamome;

        /**
         * Registers a receiver for given command. The receiver function receives a JSON message from the native.
         * The receiver format is fallowing.
         *
         * ```
         * function(json, resolve, reject) {
         *     // Something to do.
         *     // If succeeded
         *     // resolve(response);   // response is any object or null
         *     // Else
         *     // reject('Error Message');
         * }
         * ```
         *
         * @param name A command name.
         * @param receiver A receiver.
         * @return Self.
         */
        addReceiver(name: string, receiver: CommandHandler): Kamome;

        /**
         * Removes a receiver for given command if it is registered.
         *
         * @param name A command name.
         * @return Self.
         */
        removeReceiver(name: string): Kamome;

        /**
         * Sends a JSON message to the native.
         *
         * @param name A command name.
         * @param data.
         * @param timeout An individual timeout for this request.
         * @return Returns a promise.
         */
        send(name: string, data: any | null = null, timeout: number | null = null): Promise;
    }

    export var KM: Kamome;
}
