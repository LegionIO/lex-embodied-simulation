# frozen_string_literal: true

require_relative 'lib/legion/extensions/embodied_simulation/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-embodied-simulation'
  spec.version       = Legion::Extensions::EmbodiedSimulation::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = "Barsalou's grounded cognition for LegionIO"
  spec.description   = 'Embodied simulation engine for LegionIO — ' \
                       'mental rehearsal, action simulation, and counterfactual reasoning'
  spec.homepage      = 'https://github.com/LegionIO/lex-embodied-simulation'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['documentation_uri'] = "#{spec.homepage}/blob/master/README.md"
  spec.metadata['changelog_uri']     = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']   = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
end
