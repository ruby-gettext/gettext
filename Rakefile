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

require "tempfile"
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
poparser_rb_path = "lib/gettext/tools/poparser.rb"
desc "Create #{poparser_rb_path}"
task :poparser => poparser_rb_path

poparser_ry_path = "src/poparser.ry"
file poparser_rb_path => poparser_ry_path do
  racc = File.join(Gem.bindir, "racc")
  tempfile = Tempfile.new("gettext-poparser")
  command_line = "#{racc} -g #{poparser_ry_path} -o #{tempfile.path}"
  ruby(command_line)
  $stderr.puts("ruby #{command_line}")

  File.open(poparser_rb_path, "w") do |poparser_rb|
    poparser_rb.puts(<<-EOH)
# -*- coding: utf-8 -*-
#
# poparser.rb - Generate a .mo
#
# Copyright (C) 2003-2009 Masao Mutoh <mutomasa at gmail.com>
# Copyright (C) 2012 Kouhei Sutou <kou@clear-code.com>
#
# You may redistribute it and/or modify it under the same
# license terms as Ruby or LGPL.

EOH

    poparser_rb.puts(tempfile.read)
  end
  $stderr.puts "Create #{poparser_rb_path}."
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

namespace :test do
  namespace :pot do
    pot_base_dir = "test/pot"
    directory pot_base_dir

    pot_paths = []
    ruby_base_paths = [
      "non_ascii", "npgettext", "nsgettext",
      "pgettext", "plural", "plural_error",
    ]
    ruby_paths = Dir.glob("test/testlib/{#{ruby_base_paths.join(',')}}.rb")
    ruby_paths.each do |ruby_path|
      pot_base_path = File.basename(ruby_path).sub(/\.rb\z/, ".pot")
      pot_path = "#{pot_base_dir}/#{pot_base_path}"
      pot_paths << pot_path
      file pot_path => [pot_base_dir, ruby_path] do
        require "gettext/tools"
        GetText.rgettext(ruby_path, pot_path)
      end
    end

    desc "Update pot files for testing"
    task :update => pot_paths
  end

  namespace :mo do
    mo_paths = []
    language_paths = Dir.glob("test/po/*")
    language_paths.each do |language_path|
      language = File.basename(language_path)
      po_paths = Dir.glob("#{language_path}/*.po")
      po_paths.each do |po_path|
        mo_base_path = File.basename(po_path).sub(/\.po\z/, ".mo")
        mo_path = "test/locale/#{language}/LC_MESSAGES/#{mo_base_path}"
        mo_paths << mo_path
        file mo_path => po_path do
          require "gettext/tools"
          GetText.rmsgfmt(po_path, mo_path)
        end
      end
    end

    desc "Update mo files for testing"
    task :update => mo_paths
  end

  desc "Prepare test environment"
  task :prepare => "test:mo:update"
end

desc 'Run all tests'
task :test => "test:prepare" do
  options = ARGV - Rake.application.top_level_tasks
  ruby "test/run-test.rb", *options
end

YARD::Rake::YardocTask.new do |t|
end

desc "Setup Ruby-GetText-Package. (for setup.rb)"
task :setup => [:makemo]
