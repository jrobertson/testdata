Gem::Specification.new do |s|
  s.name = 'testdata'
  s.version = '1.1.11'
  s.summary = 'A test framework which accepts test data in a Polyrex format.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/testdata.rb']
  s.add_runtime_dependency('app-routes', '~> 0.1', '>=0.1.19')
  s.add_runtime_dependency('testdata_text', '~> 0.2', '>=0.2.2')
  s.add_runtime_dependency('diffyc32', '~> 0.1', '>=0.1.1')
  s.add_runtime_dependency('polyrex', '~> 1.3', '>=1.3.4')
  s.signing_key = '../privatekeys/testdata.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/testdata'
  s.required_ruby_version = '>= 2.1.2'
end
