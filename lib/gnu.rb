require 'command_parser'

# Parse the parameter hash using the GNU standard
class Gnu < Command_parser
  
  def initialize
    super
  end
  
  # This method convert a hash {parameter => value} in a string ready to
  # be passed to a command that uses GNU style to parse command line
  # parameters
  def parse
    result = ""

    @params.each do |param, value|
      # If params is followed by a value, it has to be preceed by two leads
      if( value != nil )
        result << "--#{param}=#{value} "
      # If no params is set, we assume that an one character words
      # is preceed by one lead and two or more characters words are
      # preceed by two leads
      else
        result << ( param.length == 1 ? "-#{param} " : "--#{param} " )
      end  
    end

    return result.strip
  end
end
