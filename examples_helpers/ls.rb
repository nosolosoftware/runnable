class LS < Runnable

  def initialize( opts = {} )
    super( opts )
  end
  
  def exceptions
    { 
    /ls: invalid(.*)/ => ArgumentError,
    /ls: error(.*)/ => IOError
    }
  end

end

