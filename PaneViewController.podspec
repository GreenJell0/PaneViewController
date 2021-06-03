Pod::Spec.new do |s|
  s.name         = "PaneViewController"
  s.version      = "6.0.0"
  s.summary      = "A side drawer controller"
  s.homepage     = "https://github.com/GreenJell0/PaneViewController"
  s.description  = <<-DESC
  A side drawer controller that toggles between modal and side by side view depending on horizontal trait collection
  DESC
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = 'Branden Russell', 'Hilton Campbell', 'Stephan Heilner', 'Nick Shelley'
  s.platform     = :ios, "14.0"
  s.source       = { :git => "https://github.com/GreenJell0/PaneViewController.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.source_files = "Sources/PaneViewController/*.{h,m,swift}"
  s.resources    = "Resources/PaneViewController/PaneViewController.xcassets"
  s.framework    = "UIKit"
  s.swift_version = '5.0'
end
