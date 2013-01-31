require "bundler/gem_tasks"
require 'rspec/core/rake_task'

desc "Run all the tests"
task :default => [:test]

desc "Make an archive as .tar.gz"
task :dist => %w[chmod ChangeLog doc] do
  sh "git archive --format=tar --prefix=#{release}/ HEAD^{tree} >#{release}.tar"
  sh "pax -waf #{release}.tar -s ':^:#{release}/:' SPEC ChangeLog doc jooxe.gemspec"
  sh "gzip -f -9 #{release}.tar"
end

desc "Install gem dependencies"
task :deps do
  require 'rubygems'
  require 'rbconfig'
  spec = Gem::Specification.load('jooxe.gemspec')
  spec.dependencies.each do |dep|
    reqs = dep.requirements_list
    reqs = (["-v"] * reqs.size).zip(reqs).flatten
    # Use system over sh, because we want to ignore errors!
    system Gem.ruby, "-S", "gem", "install", '--conservative', dep.name, *reqs
  end
end

desc "Make an official release"
task :officialrelease do
  puts "Official build for #{release}..."
  sh "rm -rf stage"
  sh "git clone --shared . stage"
  sh "cd stage && rake officialrelease_really"
  sh "mv stage/#{release}.tar.gz stage/#{release}.gem ."
end

task :officialrelease_really => %w[dist gem] do
  sh "sha1sum #{release}.tar.gz #{release}.gem"
end

def release
  "rack-#{File.read("jooxe.gemspec")[/s.version *= *"(.*?)"/, 1]}"
end

desc "Make binaries executable"
task :chmod do
  Dir["bin/*"].each { |binary| File.chmod(0775, binary) }
  Dir["test/cgi/test*"].each { |binary| File.chmod(0775, binary) }
end

desc "Generate a ChangeLog"
task :changelog => %w[ChangeLog]

file '.git/index'
file "ChangeLog" => '.git/index' do
  File.open("ChangeLog", "w") { |out|
    `git log -z`.split("\0").map { |chunk|
      author = chunk[/Author: (.*)/, 1].strip
      date = chunk[/Date: (.*)/, 1].strip
      desc, detail = $'.strip.split("\n", 2)
      detail ||= ""
      detail = detail.gsub(/.*darcs-hash:.*/, '')
      detail.rstrip!
      out.puts "#{date}  #{author}"
      out.puts "  * #{desc.strip}"
      out.puts detail  unless detail.empty?
      out.puts
    }
  }
end

desc "Run all the unit + spec tests"
task :test => %w[spec] 

desc "Run all the tests we run on CI"
task :ci => :test

desc "Run all the tests"
task :fulltest => %w[spec chmod] 

task :gem  do
  sh "gem build jooxe.gemspec"
end


desc "Generate RDoc documentation"
task :doc => %w[ChangeLog ] do
  sh(*%w{rdoc --line-numbers --main README.md
              --title 'Jooxe\ Documentation' --charset utf-8 -U -o doc} +
              %w{README.md KNOWN-ISSUES SPEC ChangeLog} +
              `git ls-files lib/\*\*/\*.rb`.strip.split)
  cp "contrib/rdoc.css", "doc/rdoc.css"
end

desc "Run all examples"
RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  #spec.rspec_opts = [Dir["lib"].to_a.join(':')]
  spec.rspec_opts = %w[--color]
end
