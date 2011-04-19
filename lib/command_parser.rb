class Command_parser
  def initialize
    @params = {}
  end

  def add_param( param, value = nil )
    @params[param] = value
  end


  # @abstract 
  def parse
  end
end
