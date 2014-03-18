Pod::Spec.new do |s|
  s.name          = 'TapkuLibrary'
  s.version       = '2.4'
  s.platform      = :ios
  s.author        = { 'Devin Ross' => 'devin@devinsheaven.com', 'Huy Nguyen' => 'huy.nguyen151190@gmail.com' }
  s.license       = { :type => 'MIT', :file => 'License.txt' }
  s.homepage      = 'https://github.com/devinross/tapkulibrary'
  s.summary       = 'tap + haiku = tapku, a well crafted open source iOS framework'
  s.description   = 'TapkuLibrary is an iOS library built on Cocoa and UIKit intended for broad ' \
                    'use in applications. If you\'re looking to see what the library can do, check ' \
                    'out the demo project included. Some major components include coverflow, calendar ' \
                    'grid, network requests and progress indicators.'
  s.source        = { :git => 'git@github.com:nguyenhuy/tapkulibrary.git' }
  s.requires_arc  = true
  s.source_files  = 'src/TapkuLibrary/*.{h,m}'
  s.resources     = 'src/TapkuLibrary.bundle'
  s.frameworks    = 'QuartzCore'
end
