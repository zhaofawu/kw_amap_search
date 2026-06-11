#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint kw_amap_search.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'kw_amap_search'
  s.version          = '0.0.1'
  s.summary          = 'Flutter AMap POI search plugin for Android and iOS.'
  s.description      = <<-DESC
Flutter plugin that wraps AMap POI keyword and nearby search with a stable
method-channel schema for Android and iOS.
                       DESC
  s.homepage         = 'https://lbs.amap.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'kw_amap_search'
  s.source           = { :path => '.' }
  s.source_files = 'kw_amap_search/Sources/kw_amap_search/**/*'
  s.dependency 'Flutter'
  s.dependency 'AMapFoundation-NO-IDFA', '1.9.0'
  s.dependency 'AMapSearch-NO-IDFA', '9.8.0'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'kw_amap_search_privacy' => ['kw_amap_search/Sources/kw_amap_search/PrivacyInfo.xcprivacy']}
end
