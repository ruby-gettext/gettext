# -*- mode: ruby; coding: utf-8 -*-

base_dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join(base_dir, "lib"))
require "gettext/version"

Gem::Specification.new do |s|
  s.name = "gettext"
  s.version = GetText::VERSION
  s.summary = 'Ruby-GetText-Package is a libary and tools to localize messages.'
  s.description = <<-EOD
Ruby-GetText-Package is a GNU GetText-like program for Ruby.
The catalog file(po-file) is same format with GNU GetText.
So you can use GNU GetText tools for maintaining.
  EOD
  s.authors = ["Kouhei Sutou", "Masao Mutoh"]
  s.email = ["kou@clear-code.com", "mutomasa at gmail.com"]
  s.homepage = "http://ruby-gettext.github.com/"
  s.rubyforge_project = "gettext"
  s.require_paths = ["lib"]
  Dir.chdir(base_dir) do
    s.files = Dir.glob("{bin,data,doc/text,lib,po,samples,src,test}/**/*")
    s.files += ["COPYING", "README.rdoc", "Rakefile", "gettext.gemspec"]
    s.executables = Dir.chdir("bin") do
      Dir.glob("*")
    end
    s.test_files = Dir.glob("test/test_*.rb")
  end

  s.add_runtime_dependency("locale")
  s.add_development_dependency("yard")
end
