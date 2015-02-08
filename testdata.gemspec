Gem::Specification.new do |s|
  s.name = 'testdata'
  s.version = '1.0.1'
  s.summary = 'testdata'
    s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_runtime_dependency('app-routes', '~> 0.1', '>=0.1.18')
  s.add_runtime_dependency('testdata_text', '~> 0.1', '>=0.1.8')
  s.add_runtime_dependency('diffy', '~> 3.0', '>=3.0.7') 
  s.signing_key = '../privatekeys/testdata.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/testdata'
  s.required_ruby_version = '>= 2.1.2'
end
