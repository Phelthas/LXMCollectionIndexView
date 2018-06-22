#
# Be sure to run `pod lib lint LXMCollectionIndexView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LXMCollectionIndexView'
  s.version          = '0.0.1'
  s.summary          = 'Adding "Index" for UICollectionView, it looks just like the UITableView index'
  s.description      = <<-DESC
  给UICollectionView添加索引控件，看起来应该和UITablView一样，目前用法跟UITablView还不太一样，等等再优化

                       DESC

  s.homepage         = 'https://github.com/billthas@gmail.com/LXMCollectionIndexView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'billthas@gmail.com' => 'billthas@gmail.com' }
  s.source           = { :git => 'https://github.com/billthas@gmail.com/LXMCollectionIndexView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'LXMCollectionIndexView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'LXMCollectionIndexView' => ['LXMCollectionIndexView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
