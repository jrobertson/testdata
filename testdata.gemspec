Gem::Specification.new do |s|
  s.name = 'testdata'
  s.version = '0.8.6'
  s.summary = 'testdata'
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('app-routes')
  s.add_dependency('testdata_text')
end
