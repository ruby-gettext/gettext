# -*- ruby -*-
#
# Rakefile for Ruby-GetText-Package
#
# This file maintains Ruby-GetText-Package.
#
# Use setup.rb or gem for installation.
# You don't need to use this file directly.
#
# Copyright(c) 2005-2009 Masao Mutoh
# Copyright(c) 2012 Kouhei Sutou <kou@clear-code.com>
# This program is licenced under the same licence as Ruby.
#

$:.unshift "./lib"

require 'rake'
require 'rubygems'
require "yard/rake/yardoc_task"
require 'rake/testtask'
require 'gettext/version'

require "bundler/gem_helper"
class Bundler::GemHelper
  undef_method :version_tag
  def version_tag
    version
  end
end
Bundler::GemHelper.install_tasks

PKG_VERSION = GetText::VERSION

############################################################
# GetText tasks for developing
############################################################
desc "Create lib/gettext/tools/poparser.rb"
task :poparser do
  poparser_path = "lib/gettext/tools/poparser.rb"
  racc = File.join(Config::CONFIG['bindir'], "racc")
  if ! FileTest.exist?(racc)
    puts "racc was not found: #{racc}"
    exit 1
  else FileTest.exist?(racc)
    ruby "#{racc} -g src/poparser.ry -o src/poparser.tmp.rb"
    $stderr.puts  %Q[ruby #{racc} -g src/poparser.ry -o src/poparser.tmp.rb]

    file = open(poparser_path, "w")

    file.print "=begin\n"
    file.print <<-EOS
  poparser.rb - Generate a .mo

  Copyright (C) 2003-2009 Masao Mutoh <mutomasa at gmail.com>

  You may redistribute it and/or modify it under the same
  license terms as Ruby.
EOS
    file.print "=end\n\n"

    tmpfile = open("src/poparser.tmp.rb")
    file.print tmpfile.read
    file.close
    tmpfile.close
    File.delete("src/poparser.tmp.rb")
    $stderr.puts "Create #{poparser_path}."
  end
end


desc "Create *.mo from *.po"
task :makemo do
  require 'gettext/tools'
  GetText.create_mofiles

  $stderr.puts "Create samples mo files."
  GetText.create_mofiles(
	:po_root => "samples/po", :mo_root => "samples/locale")

  $stderr.puts "Create samples/cgi mo files."
  GetText.create_mofiles(
	:po_root => "samples/cgi/po", :mo_root => "samples/cgi/locale")

  $stderr.puts "Create test mo files."
  GetText.create_mofiles(
	:po_root => "test/po", :mo_root => "test/locale")
end

desc "Update pot/po files to match new version."
task :updatepo do
  begin
    require 'gettext'
    require 'gettext/tools/poparser'
    require 'gettext/tools'
  rescue LoadError
    puts "gettext/tools/poparser was not found."
  end

  #lib/gettext/*.rb -> rgettext.po
  GetText.update_pofiles("rgettext",
                         Dir.glob("lib/**/*.rb") + ["src/poparser.ry"],
                         "ruby-gettext #{GetText::VERSION}")
end

desc "Gather the newest po files. (for me)"
task :gatherpo => [:updatepo] do
  mkdir_p "pofiles/original" unless FileTest.exist? "pofiles/original"
  Dir.glob("**/*.pot").each do |f|
    unless /^(pofiles|test)/ =~ f
      copy f, "pofiles/original/"
    end
  end
  Dir.glob("**/*.po").each do |f|
    unless /^(pofiles|test)/ =~ f
      lang = /po\/([^\/]*)\/(.*.po)/.match(f).to_a[1]
      mkdir_p "pofiles/#{lang}" unless FileTest.exist? "pofiles/#{lang}"
      copy f, "pofiles/#{lang}/"
      Dir.glob("pofiles/original/*.pot").each do |f|
        newpo = "pofiles/#{lang}/#{File.basename(f, ".pot")}.po"
        copy f, newpo unless FileTest.exist? newpo
      end
    end
  end
end

def mv_pofiles(src_dir, target_dir, lang)
   target = File.join(target_dir, lang)
   unless File.exist?(target)
     mkdir_p target
     sh "cvs add #{target}"
   end
   cvs_add_targets = ""
   Dir.glob(File.join(target_dir, "ja/*.po")).sort.each do |f|
     srcfile = File.join(src_dir, File.basename(f))
     if File.exist?(srcfile)
       unless File.exist?(File.join(target, File.basename(f)))
         cvs_add_targets << File.join(target, File.basename(f)) + " "
       end
       mv srcfile, target, :verbose => true
     else
       puts "mv #{srcfile} #{target}/ -- skipped"
     end
   end
   sh "cvs add #{cvs_add_targets}" if cvs_add_targets.size > 0
end

desc "Deploy localized pofiles to current source tree. (for me)"
task :deploypo do
     srcdir = ENV["SRCDIR"] ||= File.join(ENV["HOME"], "pofiles")
     lang = ENV["LOCALE"]
     unless lang
       puts "USAGE: rake deploypo [SRCDIR=#{ENV["HOME"]}/pofiles] LOCALE=ja"
       exit
    end
    puts "SRCDIR = #{srcdir}, LOCALE = #{lang}"

    mv_pofiles(srcdir, "po", lang)
    mv_pofiles(srcdir, "samples/cgi/po", lang)
    mv_pofiles(srcdir, "samples/po", lang)
end


task :package => [:makemo]

############################################################
# Misc tasks
############################################################
desc 'Run all tests'
task :test do
   Dir.chdir("test") do
     if RUBY_PLATFORM =~ /win32/
       sh "rake.bat", "test"
     else
       ruby "-S", "rake", "test"
     end
   end
end

YARD::Rake::YardocTask.new do |t|
end

desc "Setup Ruby-GetText-Package. (for setup.rb)"
task :setup => [:makemo]
