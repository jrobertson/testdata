Gem::Specification.new do |s|
  s.name = 'testdata'
  s.version = '0.8.7'
  s.summary = 'testdata'
    s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('app-routes')
  s.add_dependency('testdata_text') 
  s.signing_key = '../privatekeys/testdata.pem'
  s.cert_chain  = ['gem-public_cert.pem']
end
