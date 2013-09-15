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
      class Error < StandardError
      end

      class ValidationError < Error
        attr_reader :reasons
        def initialize(reasons)
          @reasons = reasons
          lines = []
          lines << "invalid configurations:"
          @reasons.each do |variable, reason|
            lines << "#{variable}: #{reason}"
          end
          super(lines.join("\n"))
        end
      end

      include GetText
      include Rake::DSL

      class << self
        # Define gettext related Rake tasks. Normally, use this method
        # to define tasks because this method is a convenient API.
        #
        # See accessor APIs how to configure this task.
        #
        # See {#define} for what task is defined.
        #
        # @example Recommended usage
        #   require "gettext/tools/task"
        #   # Recommended usage
        #   GetText::Tools::Task.define do |task|
        #     task.spec = spec
        #     # ...
        #   end
        #   # Low level API
        #   task = GetText::Tools::Task.new
        #   task.spec = spec
        #   # ...
        #   task.define
        #
        # @yield [task] Gives the newely created task to the block.
        # @yieldparam [GetText::Tools::Task] task The task that should be
        #   configured.
        # @see {#define}
        # @return [void]
        def define
          task = new
          yield(task)
          task.define
        end
      end

      # @return [Gem::Specification, nil] Package information associated
      #   with the task.
      attr_reader :spec

      # @return [String, nil] Package name for messages.
      attr_accessor :package_name

      # @return [String, nil] Package version for messages.
      attr_accessor :package_version

      # It is a required parameter.
      #
      # @return [Array<String>] Supported locales. It is filled from
      #   {#po_base_directory} by default.
      attr_accessor :locales
      attr_accessor :po_base_directory
      # @return [String] Base directory that has generated MOs. MOs
      #   are generated into
      #   `#{mo_base_directory}/#{locale}/LC_MESSAGES/#{domain}.mo`.
      attr_accessor :mo_base_directory
      # It is a required parameter.
      #
      # @return [Array<String>] Files that have messages.
      attr_accessor :files
      # It is a required parameter.
      #
      # @return [String] Text domain
      attr_accessor :domain
      attr_accessor :namespace_prefix
      # @return [Array<String>] Command line options for extracting messages
      #   from sources.
      # @see GetText::Tools::XGetText
      # @see `rxgettext --help`
      attr_reader :xgettext_options

      # @return [Bool]
      # @see #enable_description? For details.
      attr_writer :enable_description

      # @return [Bool]
      # @see #enable_po? For details.
      attr_writer :enable_po

      # @param [Gem::Specification, nil] spec Package information associated
      #   with the task. Some information are extracted from the spec.
      # @see #spec= What information are extracted from the spec.
      def initialize(spec=nil)
        initialize_variables
        self.spec = spec
        if spec
          yield(self) if block_given?
          warn("Use #{self.class.name}.define instead of #{self.class.name}.new(spec).")
          define
        end
      end

      # Sets package infromation by Gem::Specification. Here is a list
      # for information extracted from the spec:
      #
      #   * {#package_name}
      #   * {#package_version}
      #   * {#domain}
      #   * {#files}
      #
      # @param [Gem::Specification] spec package information for the
      #   i18n application.
      def spec=(spec)
        @spec = spec
        return if @spec.nil?

        @package_name = spec.name
        @package_version = spec.version.to_s
        @domain ||= spec.name
        @files += target_files
      end

      # Define tasks from configured parameters.
      #
      # TODO: List defined Rake tasks.
      def define
        ensure_variables
        validate

        define_file_tasks
        if namespace_prefix
          namespace_recursive namespace_prefix do
            define_named_tasks
          end
        else
          define_named_tasks
        end
      end

      # If it is true, each task has description. Otherwise, all tasks
      # doesn't have description.
      #
      # @return [Bool]
      # @since 3.0.1
      def enable_description?
        @enable_description
      end

      # If it is true, PO related tasks are defined. Otherwise, they
      # are not defined.
      #
      # This parameter is useful to manage PO written by hand.
      #
      # @return [Bool]
      # @since 3.0.1
      def enable_po?
        @enable_po
      end

      private
      def initialize_variables
        @spec = nil
        @package_name = nil
        @package_version = nil
        @locales = []
        @po_base_directory = "po"
        @mo_base_directory = "locale"
        @files = []
        @domain = nil
        @namespace_prefix = nil
        @xgettext_options = []
        @enable_description = true
        @enable_po = true
      end

      def ensure_variables
        @locales = detect_locales if @locales.empty?
      end

      def validate
        reasons = {}
        if @locales.empty?
          reasons["locales"] = "must set one or more locales"
        end
        if @enable_po and @files.empty?
          reasons["files"] = "must set one or more files"
        end
        if @domain.nil?
          reasons["domain"] = "must set domain"
        end
        raise ValidationError.new(reasons) unless reasons.empty?
      end

      def desc(*args)
        return unless @enable_description
        super
      end

      def define_file_tasks
        define_pot_file_task

        locales.each do |locale|
          define_po_file_task(locale)
          define_mo_file_task(locale)
        end
      end

      def define_pot_file_task
        return unless @enable_po

        pot_dependencies = files.dup
        unless File.exist?(po_base_directory)
          directory po_base_directory
          pot_dependencies << po_base_directory
        end
        file pot_file => pot_dependencies do
          command_line = [
            "--output", pot_file,
          ]
          if package_name
            command_line.concat(["--package-name", package_name])
          end
          if package_version
            command_line.concat(["--package-version", package_version])
          end
          command_line.concat(@xgettext_options)
          command_line.concat(files)
          GetText::Tools::XGetText.run(*command_line)
        end
      end

      def define_po_file_task(locale)
        return unless @enable_po

        _po_file = po_file(locale)
        po_dependencies = [pot_file]
        _po_directory = po_directory(locale)
        unless File.exist?(_po_directory)
          directory _po_directory
          po_dependencies << _po_directory
        end
        file _po_file => po_dependencies do
          if File.exist?(_po_file)
            GetText::Tools::MsgMerge.run(_po_file, pot_file,
                                         "--output", _po_file)
          else
            GetText::Tools::MsgInit.run("--input", pot_file,
                                        "--output", _po_file,
                                        "--locale", locale.to_s)
          end
        end
      end

      def define_mo_file_task(locale)
        _po_file  = po_file(locale)
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

      def define_named_tasks
        namespace :gettext do
          if @enable_po
            define_pot_tasks
            define_po_tasks
          end

          define_mo_tasks
        end

        desc "Update *.mo"
        task :gettext => (current_scope + ["gettext", "mo", "update"]).join(":")
      end

      def define_pot_tasks
          namespace :pot do
            desc "Create #{pot_file}"
            task :create => pot_file
          end
      end

      def define_po_tasks
          namespace :po do
            desc "Add a new locale"
            task :add, [:locale] do |_task, args|
              locale = args.locale || ENV["LOCALE"]
              if locale.nil?
                raise "specify locale name by " +
                  "'rake #{_task.name}[${LOCALE}]' or " +
                  "rake #{_task.name} LOCALE=${LOCALE}'"
              end
              define_po_file_task(locale)
              Rake::Task[po_file(locale)].invoke
            end

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
      end

      def define_mo_tasks
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
        File.join(mo_base_directory, locale.to_s, "LC_MESSAGES")
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
