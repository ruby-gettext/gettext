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
  end
end
