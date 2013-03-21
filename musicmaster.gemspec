# This file is a dummy gemspec that bundle asks for
# This project is packaged using RubyPackager: http://rubypackager.sourceforge.net

Gem::Specification.new do |s|
  s.name        = 'MusicMaster'
  s.version     = '0.0.1'
  # TODO: Use Rake 10 as soon as it behaves correctly
  s.add_dependency('rake', '~> 0.9')
  s.add_dependency('rUtilAnts', '>= 1.0')
  s.add_dependency('WaveSwissKnife', '>= 0.0.1')
end
