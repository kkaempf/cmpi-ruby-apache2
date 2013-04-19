require 'rubygems'

VERSION  = '0.4.0'
TOPLEVEL = File.dirname(__FILE__)
NAME     = File.basename TOPLEVEL
MOFDIR   = "/usr/share/mof/#{NAME}"
CMPIDIR  = "/usr/share/cmpi"
DESTDIR  = ENV['DESTDIR']

task :default => [:test]


spec = Gem::Specification.find_by_name("provider-testing")
gem_lib = File.join(spec.gem_dir, "lib")
$LOAD_PATH.unshift(gem_lib)
ENV['TOPLEVEL'] = TOPLEVEL

Dir[File.join(gem_lib, "tasks", "**", "*.rake")].each { |t| load t }

Dir['tasks/**/*.rake'].each { |t| load t }
