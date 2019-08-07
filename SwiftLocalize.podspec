Pod::Spec.new do |s|
  s.name             = 'SwiftLocalize'
  s.version          = '1.5.0'
  s.summary          = 'A short description of SwiftLocalize.'

  s.description      = <<-DESC
	TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/dankinsoid/SwiftLocalize'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'voidilov' => 'voidilov@gmail.com' }
  s.source           = { :git => 'https://github.com/dankinsoid/SwiftLocalize.git', :branch => 'release',  :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'Sources/SwiftLocalize/**/*'
  s.swift_versions = '5.0'

end
