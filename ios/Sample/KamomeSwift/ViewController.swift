//
//  ViewController.swift
//  KamomeSwift
//
//  Copyright (c) 2020 Hituzi Ando. All rights reserved.
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

    private var kamome: Kamome!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the Kamome object with default webView.
        self.kamome = Kamome(webView: self.webView)

        kamome.add(Command(name: "echo") { commandName, data, completion in
                  // Received `echo` command.
                  // Then send resolved result to the JavaScript callback function.
                  completion.resolve(with: ["message": data!["message"]!])
              })
              .add(Command(name: "echoError") { commandName, data, completion in
                  // Send rejected result if failed.
                  completion.reject(with: "Echo Error!")
              })
              .add(Command(name: "tooLong") { commandName, data, completion in
                  // Too long process...
                  Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { timer in
                      completion.resolve()
                  }
              })
              .add(Command(name: "getUser") { commandName, data, completion in
                  completion.resolve(with: ["name": "Brad"])
              })
              .add(Command(name: "getScore") { commandName, data, completion in
                  completion.resolve(with: ["score": 88, "rank": 2])
              })
              .add(Command(name: "getAvg") { commandName, data, completion in
                  completion.resolve(with: ["avg": 68])
              })

        kamome.howToHandleNonExistentCommand = .rejected

        // Option: Set console.log/.warn/.error adapter.
        ConsoleLogAdapter().setTo(self.webView)

        let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www")!
        self.webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
        view.addSubview(self.webView)
        view.sendSubviewToBack(self.webView)

        self.view.addSubview(self.sendButton)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.view.topAnchor),
            webView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            webView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            sendButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 88),
            sendButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -8),
            sendButton.widthAnchor.constraint(equalToConstant: 100),
            sendButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    @IBAction func sendButtonPressed(_ sender: Any) {
        // Send a data to JavaScript.
        kamome.sendMessage(with: ["greeting": "Hello! by Swift"], name: "greeting") { (commandName, result, error) in
            // Received a result from the JS code.
            guard let result = result else { return }
            print("result: \(result)")
        }
    }
}
