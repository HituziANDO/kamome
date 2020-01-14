//
//  ViewController.swift
//  KamomeSwift
//
//  Copyright (c) 2020 Hituzi Ando. All rights reserved.
//

import UIKit
import WebKit
import KamomeSDK

class MyWebView: WKWebView {
    // Something
}

class ViewController: UIViewController {

    private lazy var sendButton: UIButton = {
        let sendButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200.0, height: 44.0))
        sendButton.backgroundColor = .purple
        sendButton.layer.cornerRadius = 22.0
        sendButton.layer.shadowColor = UIColor.black.cgColor
        sendButton.layer.shadowOpacity = 0.4
        sendButton.layer.shadowOffset = CGSize(width: 0, height: 4.0)
        sendButton.setTitle("Send Data to Web", for: .normal)
        sendButton.addTarget(self, action: #selector(sendButtonPressed(_:)), for: .touchUpInside)
        return sendButton
    }()

    private var webView: MyWebView!
    private var kamome: KMMKamome!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Creates a Kamome object with default webView.
        var webView: AnyObject!
        kamome = KMMKamome.create(webView: &webView, class: MyWebView.self, frame: view.frame)
        self.webView = webView as? MyWebView

        // Creates a Kamome object for a customized webView.
//        kamome = KMMKamome()
//
//        let userContentController = WKUserContentController()
//        userContentController.add(kamome!, name: KMMScriptMessageHandlerName)
//        let configuration = WKWebViewConfiguration()
//        configuration.userContentController = userContentController
//        self.webView = WKWebView(frame: view.frame, configuration: configuration)
//
//        kamome.setWebView(self.webView)

        kamome.add(KMMCommand(name: "echo") { commandName, data, completion in
                  // Success
                  completion.resolve(with: ["message": data!["message"]!])
              })
              .add(KMMCommand(name: "echoError") { commandName, data, completion in
                  // Failure
                  completion.reject(with: "Echo Error!")
              })
              .add(KMMCommand(name: "tooLong") { commandName, data, completion in
                  // Too long process...
                  Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { timer in
                      completion.resolve()
                  }
              })
              .add(KMMCommand(name: "getUser") { commandName, data, completion in
                  completion.resolve(with: ["name": "Brad"])
              })
              .add(KMMCommand(name: "getScore") { commandName, data, completion in
                  completion.resolve(with: ["score": 88, "rank": 2])
              })
              .add(KMMCommand(name: "getAvg") { commandName, data, completion in
                  completion.resolve(with: ["avg": 68])
              })

        let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www")!
        self.webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
        view.addSubview(self.webView)
        view.sendSubviewToBack(self.webView)

        self.view.addSubview(self.sendButton)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.sendButton.center = CGPoint(x: self.view.center.x, y: self.view.frame.size.height - 70.0)
    }

    @IBAction func sendButtonPressed(_ sender: Any) {
        // Send data to JavaScript.
        kamome.sendMessage(with: ["greeting": "Hello! by Swift"], name: "greeting") { result in
            guard let result = result else { return }
            print("result: \(result)")
        }
    }
}
