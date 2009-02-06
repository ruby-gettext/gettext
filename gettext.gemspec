require 'lib/gettext/version'
Gem::Specification.new do |s|
  s.name = 'gettext'
  s.version = GetText::VERSION
  s.summary = 'Ruby-GetText-Package is a libary and tools to localize messages.'
  s.author = 'Masao Mutoh'
  s.email = 'mutoh@highway.ne.jp'
  s.homepage = 'http://gettext.rubyforge.org/'
  s.rubyforge_project = "gettext"
  s.files = FileList['**/*'].to_a.select{|v| v !~ /pkg|CVS/}
  s.require_path = 'lib'
  s.executables = Dir.entries('bin').delete_if {|item| /^\.|CVS|~$/ =~ item }
  s.bindir = 'bin'
  s.has_rdoc = true
  s.description = <<-EOF
        Ruby-GetText-Package is a GNU GetText-like program for Ruby.
        The catalog file(po-file) is same format with GNU GetText.
        So you can use GNU GetText tools for maintaining.
  EOF
end