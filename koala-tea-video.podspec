#
# Be sure to run `pod lib lint koala-tea-video.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'koala-tea-video'
  s.version          = '0.1.0'
  s.summary          = 'A short description of koala-tea-video.'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'nothing'

  s.homepage         = 'https://github.com/themisterholliday/koala-tea-video'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'themisterholliday' => 'themisterholliday@gmail.com' }
  s.source           = { :git => 'https://github.com/themisterholliday/koala-tea-video.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.3'
  s.swift_version = '4.2'

  s.source_files = 'koala-tea-video/Classes/**/*'

  # s.resource_bundles = {
  #   'koala-tea-video' => ['koala-tea-video/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'SwifterSwift', '~> 4.6.0'
  s.dependency 'Repeat', '~> 0.5.7'
  s.dependency 'Quick', '~> 1.3.4'
  s.dependency 'Nimble', '~> 7.3.4'
end
