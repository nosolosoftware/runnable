require 'command_parser'

# Parse the parameter hash using the extended standard
class Extended < Command_parser  

  # Convert a hash in a Extended style string options
  # @return [String] Extended style raw character array
  def parse
    options = ""
    @params.each do | param , value |
      options = "#{options} -#{param} #{value} "
    end
    options.strip
  end

end
