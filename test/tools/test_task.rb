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
end
