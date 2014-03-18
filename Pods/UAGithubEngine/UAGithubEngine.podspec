Pod::Spec.new do |s|
  s.name     = 'UAGithubEngine'
  s.version  = '2.4'
  s.license  = 'MIT'
  s.summary  = 'Objective-C wrapper for the Github API.'
  s.homepage = 'http://github.com/owainhunt/uagithubengine'
  s.author   = { 'Owain R Hunt' => 'owain@underscoreapps.com', 'Huy Nguyen' => 'huy.nguyen151190@gmail.com' }
  s.source   = { :git => 'git@github.com:nguyenhuy/UAGithubEngine.git' }
  s.source_files = 'UAGithubEngine', 'UAGithubEngine/**/*.{h,m}'
  s.framework = 'SystemConfiguration'
  s.requires_arc = true
end
