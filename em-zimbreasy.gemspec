# -*- encoding: utf-8 -*-
require File.expand_path('../lib/em-zimbreasy/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Prince", "Christopher Rankin"]
  gem.email         = ["crankin@pangeaequity.com"]
  gem.description   = %q{{A no-nonsense async gem for the nonsensical Zimbra API.}
  gem.summary       = %q{A no-nonsense async gem for the nonsensical Zimbra API.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "em-zimbreasy"
  gem.require_paths = ["lib"]
  gem.version       = Em::Zimbreasy::VERSION

  gem.add_dependency 'test-unit'
  gem.add_dependency 'savon', :git => 'git://github.com/rankin/savon.git'
	gem.add_dependency 'em-http-request'
	gem.add_dependency 'em-synchrony'
  gem.add_dependency 'nokogiri'
  gem.add_dependency 'icalendar'
end
