require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'
require 'spec/rake/spectask'

GEM = "compiler"
GEM_VERSION = "0.5.0"
AUTHOR = "Yehuda Katz"
EMAIL = "wycats@gmail.com"
HOMEPAGE = "http://yehudakatz.com"
SUMMARY = "A gem that provides additional book features to the flying saucer binary"

spec = Gem::Specification.new do |s|
  s.name = GEM
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  
  # Uncomment this to add a dependency
  s.add_dependency "maruku"
  s.add_dependency "imagesize"
  s.bindir = "bin"
  s.executables = "slurper"
  
  s.require_path = 'lib'
  s.autorequire = GEM
  s.files = %w(LICENSE README Rakefile) + Dir.glob("{lib,specs,bin}/**/*")
end

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = %w(--color)
  t.spec_files = Dir["spec/compiler_spec.rb"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "install the gem locally"
task :install => [:package] do
  `sudo #{Gem.ruby} -S gem install pkg/#{GEM}-#{GEM_VERSION}`
end

desc "create a gemspec file"
task :make_spec do
  File.open("#{GEM}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end