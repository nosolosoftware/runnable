require 'command_parser'

# Parse the parameter hash using the GNU standard
class Gnu < Command_parser

  # This method convert a hash {parameter => value} in a string ready to
  # be passed to a command that uses GNU style to parse command line
  # parameters
  def parse
    result = ""

    @params.each do |param, value|      
      # We assume that an one character words is preceed by one
      # lead and two or more characters words are preceed by two 
      # leads
      result << ( param.length == 1 ? "-#{param} " : "--#{param} " )
      if( value != nil )
        result << ( param.length == 1 ? "#{value}" : "=#{value}" )
      end
    end

    return result.strip
  end
end
