#
# Be sure to run `pod lib lint KoalaTeaAssetPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KoalaTeaAssetPlayer'
  s.version          = '0.2.3'
  s.summary          = 'KoalaTeaAssetPlayer is a wrapper around AVPlayer for audio and video.'
  s.homepage         = 'https://github.com/themisterholliday/KoalaTeaAssetPlayer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Craig Holliday' => 'hello@craigholliday.net' }
  s.source           = { :git => 'https://github.com/themisterholliday/KoalaTeaAssetPlayer.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/TheMrHolliday'

  s.ios.deployment_target = '10.3'
  s.swift_version = '5.0'

  s.source_files = 'KoalaTeaAssetPlayer/Classes/**/*'

  s.dependency 'SwifterSwift', '~> 5.0.0'
  s.dependency 'SwiftLint', '~> 0.33.0'

  s.resources = ['KoalaTeaAssetPlayer/Assets/**/*']
end
