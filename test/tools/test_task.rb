# -*- coding: utf-8 -*-
#
# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
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

require "gettext/tools/task"

class TestToolsTask < Test::Unit::TestCase
  setup
  def setup_application
    @application = Rake::Application.new
    @original_application = Rake.application
    Rake.application = @application
  end

  teardown
  def teardown
    Rake.application = @original_application
  end

  setup
  def setup_record_task_metadata
    @original_record_task_metadata = Rake::TaskManager.record_task_metadata
    Rake::TaskManager.record_task_metadata = true
  end

  teardown
  def teardown_record_task_metadata
    Rake::TaskManager.record_task_metadata = @original_record_task_metadata
  end

  class TestPackageName < self
    def setup
      @task = GetText::Tools::Task.new
    end

    def test_default
      assert_nil(@task.package_name)
    end

    def test_accessor
      package_name = "great application"
      @task.package_name = package_name
      assert_equal(package_name, @task.package_name)
    end

    def test_spec
      spec = Gem::Specification.new
      spec.name = "great-application"
      @task.spec = spec
      assert_equal(spec.name, @task.package_name)
    end
  end

  class TestPackageVersion < self
    def setup
      @task = GetText::Tools::Task.new
    end

    def test_default
      assert_nil(@task.package_version)
    end

    def test_accessor
      package_version = "1.0"
      @task.package_version = package_version
      assert_equal(package_version, @task.package_version)
    end

    def test_spec
      version = "1.0"
      spec = Gem::Specification.new
      spec.version = version
      @task.spec = spec
      assert_equal(version, @task.package_version)
    end
  end

  class TestDomain < self
    def setup
      @task = GetText::Tools::Task.new
    end

    def test_default
      assert_nil(@task.domain)
    end

    def test_accessor
      domain = "hello"
      @task.domain = domain
      assert_equal(domain, @task.domain)
    end

    class TestSpec < self
      def setup
        super
        @spec = Gem::Specification.new
        @spec.name = "hello"
      end

      def test_not_set
        @task.spec = @spec
        assert_equal(@spec.name, @task.domain)
      end

      def test_already_set
        domain = "#{@spec.name}-world"
        @task.domain = domain
        @task.spec = @spec
        assert_equal(domain, @task.domain)
      end
    end
  end

  class TestFiles < self
    def setup
      @task = GetText::Tools::Task.new
    end

    def test_default
      assert_equal([], @task.files)
    end

    def test_accessor
      files = [
        "lib/hellor.rb",
        "lib/world.rb",
      ]
      @task.files = files
      assert_equal(files, @task.files)
    end

    class TestSpec < self
      def setup
        super
        @spec = Gem::Specification.new
        @spec.files = [
          "lib/hellor.rb",
          "lib/world.rb",
        ]
      end

      def test_not_set
        @task.spec = @spec
        assert_equal(@spec.files, @task.files)
      end

      def test_already_set
        files = [
          "lib/hello/world.rb",
        ]
        @task.files = files
        @task.spec = @spec
        assert_equal(files + @spec.files, @task.files)
      end
    end

    class TestTask < self
      class TestPOT < self
        def setup
          super
          @task.domain = "hello"
          @pot_file = @task.send(:pot_file)
        end

        def test_empty
          @task.files = []
          @task.define
          assert_raise(RuntimeError) do
            Rake::Task[@pot_file]
          end
        end

        def test_not_empty
          @task.files = [__FILE__]
          @task.define
          assert_equal([__FILE__],
                       Rake::Task[@pot_file].prerequisites)
        end
      end

      class TestPO < self
        def setup
          super
          @task.domain = "hello"
          @locale = "ja"
          @task.locales = [@locale]
          @po_file = @task.send(:po_file, @locale)
        end

        def test_empty
          @task.files = []
          @task.define
          assert_raise(RuntimeError) do
            Rake::Task[@po_file]
          end
        end

        def test_not_empty
          @task.files = [__FILE__]
          @task.define
          assert_equal([@task.send(:pot_file)],
                       Rake::Task[@po_file].prerequisites)
        end
      end

      class TestMO < self
        def setup
          super
          @task.domain = "hello"
          @locale = "ja"
          @task.locales = [@locale]
          @po_file = @task.send(:po_file, @locale)
          @mo_file = @task.send(:mo_file, @locale)
        end

        def test_prerequisites
          @task.define
          assert_equal([@po_file],
                       Rake::Task[@mo_file].prerequisites)
        end
      end
    end
  end

  class TestEnableDescription < self
    def setup
      @task = GetText::Tools::Task.new
    end

    def test_default
      assert_true(@task.enable_description?)
    end

    def test_accessor
      @task.enable_description = false
      assert_false(@task.enable_description?)
    end

    class TestTask < self
      def test_true
        @task.enable_description = true
        @task.define
        assert_not_nil(task.comment)
      end

      def test_false
        @task.enable_description = false
        @task.define
        assert_nil(task.comment)
      end

      private
      def task
        Rake::Task["gettext:po:update"]
      end
    end
  end
end
