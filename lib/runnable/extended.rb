require 'command_parser'

# Parse the parameter hash using the extended standard
class Extended < Command_parser  

  # Parse all the params passed as arguments
  # @return String
  def parse
    options = ""
    @params.each do | param , value |
      options = "#{options} -#{param} #{value} "
    end
    options.strip
  end

end
