require 'command_parser'

class Extended < Command_parser  

  def initialize
    super
  end

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
