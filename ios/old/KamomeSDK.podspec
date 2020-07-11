Pod::Spec.new do |s|
  s.name         = "KamomeSDK"
  s.version      = "3.1.0"
  s.summary      = "Kamome bridges a gap between JavaScript in the WKWebView and the native code written by Swift or Objective-C."
  s.description  = <<-DESC
  Kamome is a library for iOS and Android apps using the WebView. This library bridges a gap between JavaScript in the WebView and the native code written by Swift, Objective-C, Java or Kotlin.
                   DESC
  s.homepage     = "https://github.com/HituziANDO/kamome"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = "Hituzi Ando"
  s.platform     = :ios, "9.3"
  s.source       = { :git => "https://github.com/HituziANDO/kamome.git", :tag => "#{s.version}" }
  s.source_files = "ios/KamomeSDK/**/*.{h,m}"
  s.requires_arc = true
end

