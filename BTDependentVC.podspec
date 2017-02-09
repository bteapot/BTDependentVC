Pod::Spec.new do |s|
  s.name                  = 'BTDependentVC'
  s.version               = '1.0.0'
  s.summary               = 'UIViewController category to respond to changes in NSManagedObject\'s state and properties.'
  s.homepage              = 'https://github.com/bteapot/BTDependentVC'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'Денис Либит' => 'bteapot@me.com' }
  s.source                = { :git => 'https://github.com/bteapot/BTDependentVC.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files          = 'BTDependentVC/**/*'
  s.frameworks            = 'UIKit', 'CoreData'
end
