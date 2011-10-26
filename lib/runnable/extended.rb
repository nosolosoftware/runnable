# Copyright 2011 NoSoloSoftware

# This file is part of Runnable.
# 
# Runnable is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Runnable is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Runnable.  If not, see <http://www.gnu.org/licenses/>.

require 'runnable/command_parser'

# Parse the parameter hash using the extended standard.
class Extended < CommandParser  

  # Convert a hash in an array of 'Extended style' option strings.
  # @return [Array] Extended-style parsed params.
  def parse
    @params.collect { |param , value|  ["-#{param}", "#{value}"] }
  end

end
