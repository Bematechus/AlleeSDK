Pod::Spec.new do |s|
  s.swift_version    = '4.2'
  s.name             = 'AlleeSDK'
  s.version          = '1.0'
  s.platform         = :ios
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.summary          = 'AlleeSDK help you to integrate your POS with our KDS' 
  s.homepage         = 'https://github.com/Bematechus/AlleeSDK'
  s.author           = { 'Logic Controls' => 'sales@bematechus.com' }
  s.source           = { :git => 'https://github.com/Bematechus/AlleeSDK.git', 
                         :tag => s.version.to_s, :submodules => true }
 
  s.ios.deployment_target = '8'

  s.source_files     = 'AlleeSDK/AlleeSDK.h', 'AlleeSDK/AlleeSDK.swift',
                       'Frameworks/AlleeCommon/Models/*.swift',
                       'Frameworks/AlleeCommon/Messages/*.swift'

  s.vendored_frameworks   = 'Frameworks/BSocketHelper.framework'
 
end
