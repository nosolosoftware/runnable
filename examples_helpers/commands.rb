# This module contains different classes that represents system commands
module Commands
  class DC < Runnable
  end

  class BC < Runnable
  end

  class Tail < Runnable
  end

  class Read < Runnable
  end

  class Yes < Runnable
    def initialize( opts = {} )
      super( opts )
    end
  end

  class VLC < Runnable
    def initialize( opts = {} )
      super( opts )
    end
  end

  class Sleep < Runnable
    def initialize( opts = {} )
      super( opts )
    end
  end

  class Grep < Runnable
    def initialize( opts = {} )
      super( opts )
    end
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

  class Find < Runnable
    command_style :extended
    
    def initialize( opts = {} )
      super( opts )
    end
  end

  class CVLC < Runnable
    command_style :gnu

    def initialize( opts = {} )
      super( opts )
    end
  end
 
  class GCC < Runnable
    command_style :gnu

    def initialize( opts = {} )
      super( opts )
    end
  end

end
