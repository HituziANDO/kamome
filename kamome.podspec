Pod::Spec.new do |s|
  s.name                  = "kamome"
  s.version               = "5.2.1"
  s.summary               = "Kamome bridges a gap between JavaScript in the WKWebView and the native code written by Swift."
  s.description           = <<-DESC
  Kamome is a library for iOS and Android apps using the WebView. This library bridges a gap between JavaScript in the WebView and the native code written by Swift, Java or Kotlin.
                   DESC
  s.homepage              = "https://github.com/HituziANDO/kamome"
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = "Hituzi Ando"
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.13'
  s.source                = { :git => "https://github.com/HituziANDO/kamome.git", :tag => "#{s.version}" }
  #s.source_files         = "ios/kamome-framework/src/*.{swift,h}"
  s.vendored_frameworks   = "ios/kamome.xcframework"
  s.requires_arc          = true
  s.swift_versions        = '5.0'
end
