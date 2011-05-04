# Base class to create a command-line parameter parser
# It holds that parameters in a hash and the child has
# to be the one who return the formatted string according
# to the stanard used.
class Command_parser
  def initialize
    @params = {}
  end

  # Add params and value to the params hash to be parsed
  # @param [String] param Parameter name
  # @param [Object] value Parameter value, nil if not set
  # @return [nil]
  def add_param( param, value = nil )
    @params[param] = value
  end

  # This method has to be overwritten in the child and
  # return the formmated string
  # @abstract 
  def parse
  end
end
