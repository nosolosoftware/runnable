class LS < Runnable

  def initialize( opts = {} )
    super( opts )
  end
  
  def exceptions
    { 
    /ls: (.*)/ => ArgumentError
    }
  end
end

