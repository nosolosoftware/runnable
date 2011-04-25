module Commands
  class Yes < Runnable

    def initialize( opts = {} )
      super( opts )
    end

  end

  class VLC < Runnable
    def initialize( opts )
      super( opts )
    end
  end

  class Tail < Runnable
  end

  class Sleep < Runnable
    def initialize( opts = {} )
      super( opts )
    end
  end

  class Read < Runnable
  end

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

  class Grep < Runnable
    def initialize( opts = {} )
      super( opts )
    end
  end

  class Find < Runnable
    command_style :extended
    
    def initialize( opts = {} )
      super( opts )
    end
  end

  class DC < Runnable
  end

  class CVLC < Runnable
    command_style :gnu

    def initialize( opts = {} )
      super( opts )
    end
  end

  class BC < Runnable
  end
end
