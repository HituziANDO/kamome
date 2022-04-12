//
//  ViewController.swift
//  KamomeSwift
//
//  Copyright (c) 2021 Hituzi Ando. All rights reserved.
//

import UIKit
import WebKit
import kamome

class MyWebView: WKWebView {

    override var safeAreaInsets: UIEdgeInsets {
        .zero
    }
}

class ViewController: UIViewController {

    private lazy var sendButton: UIButton = {
        let sendButton = UIButton()
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(named: "send_button"), for: .normal)
        sendButton.addTarget(self, action: #selector(sendButtonPressed(_:)), for: .touchUpInside)
        return sendButton
    }()

    private lazy var webView: MyWebView = {
        let webView = MyWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        return webView
    }()

    private var client: Client!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Creates the Client object with the webView.
        client = Client(webView)
                .add(Command("echo") { commandName, data, completion in
                    // Received `echo` command.
                    // Then sends resolved result to the JavaScript callback function.
                    completion.resolve(["message": data!["message"]!])
                })
                .add(Command("echoError") { commandName, data, completion in
                    // Sends rejected result if failed.
                    completion.reject("Echo Error! ['\"+-._~\\@#$%^&*=,/?;:|{}]")
                })
                .add(Command("tooLong") { commandName, data, completion in
                    // Too long process...
                    Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { timer in
                        completion.resolve()
                    }
                })

        client.howToHandleNonExistentCommand = .rejected

        // Set a ready event handler.
        // The handler is called when the Kamome JavaScript library goes ready state.
        client.readyEventHandler = {
            print("client.isReady is \(self.client.isReady) after loading the web page")
        }
        print("client.isReady is \(client.isReady) before loading the web page")

        // If the client sends a message before the webView has loaded the web page,
        // it waits for the JS library is ready.
        // When the library is ready, the client retries to send.
        client.send(["greeting": "Hi!"], commandName: "greeting") { _, result, _ in
            guard let result = result else { return }
            print("result: \(result)")
        }

        // Option: Sets console.log/.warn/.error/.assert adapter.
        ConsoleLogAdapter().setTo(webView)

        let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www")!
        webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
        view.addSubview(webView)
        view.sendSubviewToBack(webView)

        view.addSubview(sendButton)

        NSLayoutConstraint.activate([
                                        webView.topAnchor.constraint(equalTo: view.topAnchor),
                                        webView.leftAnchor.constraint(equalTo: view.leftAnchor),
                                        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                        webView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                        sendButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 88),
                                        sendButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
                                        sendButton.widthAnchor.constraint(equalToConstant: 100),
                                        sendButton.heightAnchor.constraint(equalToConstant: 60),
                                    ])
    }

    @IBAction func sendButtonPressed(_ sender: Any) {
        // Sends a data to the JS code.
        client.send(["greeting": "Hello! by Swift ['\"+-._~\\@#$%^&*=,/?;:|{}]"], commandName: "greeting") { (commandName, result, error) in
            // Received a result from the JS code.
            guard let result = result else { return }
            print("result: \(result)")
        }
    }
}
