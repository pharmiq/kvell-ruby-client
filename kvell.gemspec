# frozen_string_literal: true

require_relative 'lib/kvell/version'

Gem::Specification.new do |spec|
  spec.name = 'kvell'
  spec.version = Kvell::VERSION
  spec.authors = ['Akhmed Magomedov']
  spec.email = ['aha252000@mail.ru']
  spec.summary = 'The client for the Kvell API'
  spec.required_ruby_version = '~> 3.0'
  spec.files = Dir['app/**/*', 'lib/**/*', 'config/**/*', 'README.md']
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
