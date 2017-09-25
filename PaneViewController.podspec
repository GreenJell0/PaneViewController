Pod::Spec.new do |s|
  s.name         = "PaneViewController"
  s.version      = "4.0.0"
  s.summary      = "A side drawer controller"
  s.homepage     = "https://www.lds.org/pages/mobileapps?lang=eng"
  s.description  = <<-DESC
A side drawer controller that toggles between modal and side by side view depending on horizontal trait collection
                   DESC
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = 'Branden Russell', 'Hilton Campbell', 'Stephan Heilner', 'Nick Shelley'
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/CrossWaterBridge/PaneViewController.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.source_files = "PaneViewController/*.{h,m,swift}"
  s.resources    = "Resources/PaneViewController.xcassets"
  s.framework    = "UIKit"
  s.dependency "ObserverSet"
end
