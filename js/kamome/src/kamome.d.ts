declare module "kamome" {
    export type ReadyListener = () => void
    export type CommandHandler = (
        data: any | null,
        resolve: (data?: any | null) => void,
        reject: (errorMessage?: string) => void,
    ) => void

    export interface Error {
        requestTimeout: string
        rejected: string
        canceled: string
    }

    export interface Client {
        /**
         * Tells whether your app has the Kamome client.
         *
         * @return true if the app has the Kamome client. Otherwise, false.
         */
        hasClient(): boolean
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
         *      // reject("Error Message");
         *  }
         *  ```
         *
         * @param name A command name.
         * @param handler A handler.
         * @return Self.
         */
        addCommand(name: string, handler: CommandHandler): Browser

        /**
         * Removes a command of specified name.
         *
         * @param name A command name that you will remove.
         * @return Self.
         */
        removeCommand(name: string): Browser

        /**
         * Tells whether specified command is registered.
         *
         * @param name A command name.
         */
        hasCommand(name: string): boolean


        /**
         * Sends a message to the receiver added by KM.addReceiver method.
         *
         * @param name A command name.
         * @param data A JSON data.
         * @return {Promise<any>}
         */
        send(name: string, data?: any | null): Promise<any>
    }

    export interface Kamome {
        /**
         * The version code of the Kamome JavaScript library.
         */
        VERSION_CODE: number
        Error: Error
        android: Client
        iOS: Client
        flutter: Client
        browser: Browser

        /**
         * Tells whether the native client is ready.
         */
        isReady(): boolean

        /**
         * Sets a ready event listener.
         * The listener is called when Kamome iOS, Android, or Flutter client goes ready state.
         *
         * @param listener A listener.
         * @return Self.
         */
        setReadyEventListener(listener: ReadyListener): Kamome

        /**
         * `KM.send` method expects a 'resolve'/'reject' response will be returned in a duration.
         * If the request is timed out, it's callback calls `reject` with requestTimeout error.
         * You can change default request timeout.
         * Sets a timeout for a request. If given `time` <= 0, the request timeout function is disabled.
         *
         * @param time A time in millisecond.
         * @return Self.
         */
        setDefaultRequestTimeout(time: number): Kamome

        /**
         * If this method returns true, KM has no native clients such as an iOS client.
         *
         * @return {boolean} true if KM has no native clients, otherwise false.
         */
        hasNoClients(): boolean

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
         *     // reject("Error Message");
         * }
         * ```
         *
         * @param name A command name.
         * @param receiver A receiver.
         * @return Self.
         */
        addReceiver(name: string, receiver: CommandHandler): Kamome

        /**
         * Removes a receiver for given command if it is registered.
         *
         * @param name A command name.
         * @return Self.
         */
        removeReceiver(name: string): Kamome

        /**
         * Sends a JSON message to the native.
         *
         * @param name A command name.
         * @param data
         * @param timeout Timeout in milliseconds for this request. If this argument is omitted or null, default timeout is used.
         * @return
         */
        send(name: string, data?: any, timeout?: number | null): Promise<any>
    }

    export const KM: Kamome
}
