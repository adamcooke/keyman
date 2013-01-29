$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'keyman'

Gem::Specification.new do |s|
  s.name = 'keyman'
  s.version = Keyman::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "A simple library for managing distributed SSH keys"
  s.description = s.summary
  s.files = Dir["**/*"]
  s.bindir = "bin"
  s.executables << 'keyman'
  s.require_path = 'lib'
  s.has_rdoc = false
  s.author = "Adam Cooke"
  s.email = "adam@atechmedia.com"
  s.homepage = "http://atechmedia.com"
  s.add_dependency('net-ssh', '~> 2.6.3')
end

