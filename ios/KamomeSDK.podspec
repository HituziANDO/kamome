Pod::Spec.new do |s|
  s.name         = "KamomeSDK"
  s.version      = "1.5.0"
  s.summary      = "Kamome is bridging JavaScript and Objective-C/Swift."
  s.description  = <<-DESC
  Kamome is a library sending messages between JavaScript and native code written by Objective-C/Swift in WKWebView.
                   DESC
  s.homepage     = "https://github.com/HituziANDO/kamome"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = "Hituzi Ando"
  s.platform     = :ios, "9.3"
  s.source       = { :git => "https://github.com/HituziANDO/kamome.git", :tag => "#{s.version}" }
  s.source_files = "ios/KamomeSDK/**/*.{h,m}"
  s.requires_arc = true
end

