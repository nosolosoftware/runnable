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

# <p>Parse the parameter hash using the GNU standard.</p>
class Gnu < Command_parser

  # This method convert a hash in a string ready to
  # be passed to a command that uses GNU style to parse command line
  # parameters.
  # @return [String] Gnu-style parsed params in a raw character array.
  def parse
    result = ""

    @params.each do |param, value|      
      # We assume that an one character words is preceed by one
      # lead and two or more characters words are preceed by two 
      # leads
      result << ( param.length == 1 ? "-#{param} " : "--#{param} " )

      # In case the param have parameter we use the correct assignation
      #   -Param followed by value (without whitespace) to one character params
      #   -Param followed by '=' and value to more than one character params
      if( value != nil )
        result << ( param.length == 1 ? "#{value}" : "=#{value}" )
      end
    end

    return result.strip
  end
end
