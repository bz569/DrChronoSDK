Pod::Spec.new do |spec|
  spec.name = "DrChronoSDK"
  spec.version = "0.5"
  spec.summary = "The drchrono SDK for iOS to connect public API"
  spec.homepage = "https://github.com/bz569/DrChronoSDK"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Boxuan Zhang" => 'boxuan@drchrono.com' }

  spec.platform = :ios, "8.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/bz569/DrChronoSDK", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "DrChronoSDK/*.{h,swift}"

  spec.dependency "OAuthSwift", "~> 0.5.0"
  spec.dependency "Swifter", "~> 1.1.3"

end
