Pod::Spec.new do |s|
  s.swift_version    = '5.0'
  s.name             = 'AlleeSDK'
  s.version          = '1.6'
  s.platform         = :ios
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.summary          = 'AlleeSDK help you to integrate your POS with our KDS' 
  s.homepage         = 'https://github.com/Bematechus/AlleeSDK'
  s.author           = { 'Logic Controls' => 'sales@bematechus.com' }
  s.source           = { :git => 'https://github.com/Bematechus/AlleeSDK.git', 
                         :tag => s.version.to_s, :submodules => true }
 
  s.ios.deployment_target = '8'

  s.source_files     = 'AlleeSDK/AlleeSDK.h', 'AlleeSDK/*.swift',
                       'Frameworks/AlleeCommon/Models/*.swift',
                       'Frameworks/AlleeCommon/Messages/*.swift'

  s.vendored_frameworks = 'Frameworks/BSocketHelper.framework'
 
end

# To send a new version follow the steps:
## Update the Cocoapods: sudo gem install cocoapods -n /usr/local/bin
## Validade the changes: pod lib lint AlleeSDK.podspec
## If validade was success so push the update: pod trunk push AlleeSDK.podspec
