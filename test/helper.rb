# Copyright (C) 2012-2020  Sutou Kouhei <kou@clear-code.com>
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

require "fileutils"
require "tmpdir"
require "tempfile"
require "time"

require "gettext"

module Helper
  module Path
    module_function
    def fixture_path(*components)
      File.join(File.dirname(__FILE__), "fixtures", *components)
    end

    def locale_path
      File.join(File.dirname(__FILE__), "locale")
    end
  end

  module Tmpdir
    def setup_tmpdir
      @tmpdir = Dir.mktmpdir
    end

    def teardown_tmpdir
      FileUtils.rm_rf(@tmpdir, :secure => true) if @tmpdir
    end
  end

  module Warning
    def suppress_warning
      stderr, $stderr = $stderr, StringIO.new
      begin
        yield
      ensure
        $stderr = stderr
      end
    end
  end
end
