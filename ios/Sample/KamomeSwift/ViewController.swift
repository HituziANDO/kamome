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
                completion.reject("Echo Error!")
            })
            .add(Command("tooLong") { commandName, data, completion in
                // Too long process...
                Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { timer in
                    completion.resolve()
                }
            })

        client.howToHandleNonExistentCommand = .rejected

        // Option: Sets console.log/.warn/.error adapter.
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
        client.send(["greeting": "Hello! by Swift"], commandName: "greeting") { (commandName, result, error) in
            // Received a result from the JS code.
            guard let result = result else { return }
            print("result: \(result)")
        }
    }
}
