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


# Base class to create a command-line parameter parser.
#
# It holds that parameters in a hash and the child has
# to be the one who return the formatted string according
# to the standard used.
class CommandParser
  # Create a new instance of the parser.
  def initialize
    @params = {}
  end

  # Add params and value to the params hash to be parsed.
  # @param [String] param Parameter name.
  # @param [Object] value Parameter value.
  # @return [nil]
  def add_param( param, value = nil )
    @params[param] = value
  end

  # This method has to be overwritten in the child
  # @abstract 
  # @return [Array]
  def parse
  end
end
