Gem::Specification.new do |s|
  s.name = 'perf_check'
  s.version = '0.0.2'
  s.date = '2014-06-30'
  s.summary = 'PERF CHECKKK!'
  s.authors = ['rubytune']
  s.homepage = 'https://github.com/rubytune/perf_check'
  s.license = 'MIT'

  s.files = ['lib/perf_check.rb',
             'lib/perf_check/server.rb',
             'lib/perf_check/test_case.rb',
             'lib/perf_check/git.rb']

  s.executables << 'perf_check'
end
