#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint arcsoft.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'arcsoft'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for using Face'
  s.description      = <<-DESC
A Flutter plugin for using Face
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  s.ios.vendored_frameworks = 'Frameworks/ArcSoftFaceEngine.framework'
  s.vendored_frameworks = 'ArcSoftFaceEngine.framework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
