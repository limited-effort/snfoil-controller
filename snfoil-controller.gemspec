# frozen_string_literal: true

require_relative 'lib/snfoil/controller/version'

Gem::Specification.new do |spec|
  spec.name          = 'snfoil-controller'
  spec.version       = SnFoil::Controller::VERSION
  spec.authors       = ['Matthew Howes', 'Cliff Campbell']
  spec.email         = ['matt.howes@limitedeffort.io', 'cliffcampbell@hey.com']

  spec.summary       = 'Seperate Display Logic from Business Logic'
  spec.description   = 'A context-like experience for your controllers'
  spec.homepage      = 'https://github.com/limited-effort/snfoil-controller'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/limited-effort/snfoil-controller/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  ignore_list = %r{\A(?:test/|spec/|bin/|features/|Rakefile|\.\w)}
  spec.files = Dir.chdir(File.expand_path(__dir__)) { `git ls-files -z`.split("\x0").reject { |f| f.match(ignore_list) } }

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 5.2.6'
  spec.add_dependency 'snfoil-context', '>= 1.0.1', '< 2.0'
end
