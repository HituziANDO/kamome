//
//  ViewController.swift
//  KamomeSwift
//
//  Created by Masaki Ando on 2019/02/03.
//  Copyright © 2019年 Hituzi Ando. All rights reserved.
//

import UIKit
import WebKit
import KamomeSDK

class ViewController: UIViewController {

    private var webView: WKWebView?
    private var kamome:  KMMKamome?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Creates a kamome instance with default webView.
        var webView: WKWebView? = nil
        kamome = KMMKamome.createInstanceAndWebView(&webView, withFrame: view.frame)
        self.webView = webView

        // Creates a kamome instance for a customized webView.
//        kamome = KMMKamome()
//
//        let userContentController = WKUserContentController()
//        userContentController.add(kamome!, name: KMMScriptMessageHandlerName)
//        let configuration = WKWebViewConfiguration()
//        configuration.userContentController = userContentController
//        self.webView = WKWebView(frame: view.frame, configuration: configuration)
//
//        kamome?.setWebView(self.webView!)

        kamome?.add(KMMCommand(name: "echo") { data, completion in
                   // Success
                   completion.resolve(with: ["message": data!["message"]!])
               })
               .add(KMMCommand(name: "get") { data, completion in
                   // Failure
                   completion.reject(with: "Error message")
               })
               .add(KMMCommand(name: "tooLong") { data, completion in
                   // Too long process
                   Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { timer in
                       completion.resolve()
                   }
               })

        let htmlURL = URL(fileURLWithPath: Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "www")!)
        self.webView!.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL)
        view.addSubview(self.webView!)
        view.sendSubviewToBack(self.webView!)
    }

    @IBAction func sendButtonPressed(_ sender: Any) {
        // Send data to JavaScript.
        kamome?.sendMessage(with: ["greeting": "Hello!"], block: { result in
            guard let result = result else { return }
            print("result: \(result)")
        }, forName: "greeting")
    }
}
