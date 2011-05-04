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

require 'command_parser'

# <p>Parse the parameter hash using the extended standard.</p>
class Extended < Command_parser  

  # Convert a hash in a Extended style string options.
  # @return [String] Extended-style parsed params in a raw character array.
  def parse
    options = ""
    @params.each do | param , value |
      options = "#{options} -#{param} #{value} "
    end
    options.strip
  end

end
