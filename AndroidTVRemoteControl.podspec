Pod::Spec.new do |s|
  s.name             = 'AndroidTVRemoteControl'
  s.version          = '1.3.5'
  s.summary          = 'Implementation of the remote control protocol v2 for Android TV.'
  s.homepage         = 'https://github.com/odyshewroman/AndroidTVRemoteControl'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Odyshew Roman' => 'odyshewroman@gmail.com' }
  s.source           = { :git => 'https://github.com/odyshewroman/AndroidTVRemoteControl.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/AndroidTVRemoteControl/**/*'
end
