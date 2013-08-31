# -*- coding: utf-8 -*-
#
# Copyright (C) 2012-2013  Kouhei Sutou <kou@clear-code.com>
#
# License: Ruby's or LGPL
#
# This library is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "rake"
require "gettext/tools"

module GetText
  module Tools
    class Task
      include GetText
      include Rake::DSL

      attr_accessor :locales, :po_base_directory, :mo_base_directory, :domain
      attr_accessor :namespace_prefix, :files
      # @return [Array<String>] Command line options for extracting messages
      #   from sources.
      # @see GetText::Tools::XGetText
      # @see `rxgettext --help`
      attr_reader :xgettext_options
      def initialize(spec)
        @spec = spec
        @locales = []
        @po_base_directory = "po"
        @mo_base_directory = "."
        @files = target_files
        @domain = @spec.name
        @namespace_prefix = nil
        @xgettext_options = []
        yield(self) if block_given?
        @locales = detect_locales if @locales.empty?
        raise("must set locales: #{inspect}") if @locales.empty?
        define
      end

      private
      def define
        define_file_tasks
        if namespace_prefix
          namespace_recursive namespace_prefix do
            define_named_tasks
          end
        else
          define_named_tasks
        end
      end

      def define_file_tasks
        unless files.empty?
          pot_dependencies = files.dup
          unless File.exist?(po_base_directory)
            directory po_base_directory
            pot_dependencies << po_base_directory
          end
          file pot_file => pot_dependencies do
            command_line = [
              "--package-name", @spec.name,
              "--package-version", @spec.version.to_s,
              "--output", pot_file,
            ]
            command_line.concat(@xgettext_options)
            command_line.concat(files)
            GetText::Tools::XGetText.run(*command_line)
          end
        end

        locales.each do |locale|
          _po_file = po_file(locale)
          unless files.empty?
            po_dependencies = [pot_file]
            _po_directory = po_directory(locale)
            unless File.exist?(_po_directory)
              directory _po_directory
              po_dependencies << _po_directory
            end
            file _po_file => po_dependencies do
              if File.exist?(_po_file)
                GetText::Tools::MsgMerge.run(po_file(locale), pot_file,
                                             "--output", _po_file)
              else
                GetText::Tools::MsgInit.run("--input", pot_file,
                                            "--output", _po_file,
                                            "--locale", locale.to_s)
              end
            end
          end

          mo_dependencies = [_po_file]
          _mo_directory = mo_directory(locale)
          unless File.exist?(_mo_directory)
            directory _mo_directory
            mo_dependencies << _mo_directory
          end
          _mo_file = mo_file(locale)
          file _mo_file => mo_dependencies do
            GetText::Tools::MsgFmt.run(_po_file, "--output", _mo_file)
          end
        end
      end

      def define_named_tasks
        namespace :gettext do
          namespace :pot do
            desc "Create #{pot_file}"
            task :create => pot_file
          end

          namespace :po do
            update_tasks = []
            @locales.each do |locale|
              namespace locale do
                desc "Update #{po_file(locale)}"
                task :update => po_file(locale)
                update_tasks << (current_scope + ["update"]).join(":")
              end
            end

            desc "Update *.po"
            task :update => update_tasks
          end

          namespace :mo do
            update_tasks = []
            @locales.each do |locale|
              namespace locale do
                desc "Update #{mo_file(locale)}"
                task :update => mo_file(locale)
                update_tasks << (current_scope + ["update"]).join(":")
              end
            end

            desc "Update *.mo"
            task :update => update_tasks
          end
        end

        desc "Update *.mo"
        task :gettext => (current_scope + ["gettext", "mo", "update"]).join(":")
      end

      def pot_file
        File.join(po_base_directory, "#{domain}.pot")
      end

      def po_directory(locale)
        File.join(po_base_directory, locale.to_s)
      end

      def po_file(locale)
        File.join(po_directory(locale), "#{domain}.po")
      end

      def mo_directory(locale)
        File.join(mo_base_directory, "locale", locale.to_s, "LC_MESSAGES")
      end

      def mo_file(locale)
        File.join(mo_directory(locale), "#{domain}.mo")
      end

      def target_files
        files = @spec.files.find_all do |file|
          /\A\.(?:rb|erb|glade)\z/i =~ File.extname(file)
        end
        files += @spec.executables.collect do |executable|
          "bin/#{executable}"
        end
        files
      end

      def detect_locales
        locales = []
        return locales unless File.exist?(po_base_directory)

        Dir.open(po_base_directory) do |dir|
          dir.each do |entry|
            next unless /\A[a-z]{2}(?:_[A-Z]{2})?\z/ =~ entry
            next unless File.directory?(File.join(dir.path, entry))
            locales << entry
          end
        end
        locales
      end

      def current_scope
        scope = Rake.application.current_scope
        if scope.is_a?(Array)
          scope
        else
          if scope.empty?
            []
          else
            [scope.path]
          end
        end
      end

      def namespace_recursive(namespace_spec, &block)
        first, rest = namespace_spec.split(/:/, 2)
        namespace first do
          if rest.nil?
            block.call
          else
            namespace_recursive(rest, &block)
          end
        end
      end
    end
  end
end
