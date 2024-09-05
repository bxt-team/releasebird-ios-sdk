#
# Be sure to run `pod lib lint releasebird-ios-sdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'releasebird-ios-sdk'
  s.version          = '1.0.8'
  s.summary          = 'A short description of releasebird-ios-sdk.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/bxt-team/releasebird-ios-sdk'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'buildnext GmbH' => 'christian.zillmann@buildnext.io' }
  s.source           = { :git => 'https://github.com/bxt-team/releasebird-ios-sdk.git', :tag => '1.0.8' }

  s.ios.deployment_target = '9.0'
  
  s.source_files = 'releasebird-ios-sdk/Classes/**/*.{h,m,c}'
  s.public_header_files = 'releasebird-ios-sdk/Classes/**/*.h'

  s.frameworks = 'UIKit'
  s.dependency 'AFNetworking', '~> 4.0.1'
end
