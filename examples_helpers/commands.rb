# This module contains different classes that represents system commands
module Commands
  class MyNMAP
    include Runnable

    executes :nmap

    define_command( :scan, :blocking => true ) { |ipaddr, subnet| "-sP #{ipaddr}/#{subnet}" }
    scan_processors(
      :exceptions => { /^Illegal netmask value/ => ArgumentError },
      :outputs => { /Nmap scan report for (.*)/ => :ip }
    )
  end

  class DC
    include Runnable
    executes :dc
  end

  class BC
    include Runnable
    executes :bc
  end

  class Tail
    include Runnable
    executes :tail
  end

  class Read
    include Runnable
    executes :read
  end

  class Yes
    include Runnable
    executes :yes
  end

  class VLC
    include Runnable
    executes :vlc
  end

  class Sleep
    include Runnable
    executes :sleep
  end

  class Grep
    include Runnable
    executes :grep
  end

  class LSNoExceptions
    include  Runnable
      
    executes :ls
  end

  class LS
    include  Runnable
      
    executes :ls

    processors( :exceptions => { /ls: .*/ => ArgumentError } )
  end

  class Find
    include Runnable

    executes :find
    command_style :extended
  end

  class Wget
    include Runnable
    
    executes :wget
  end

  class CVLC
    include Runnable
    
    executes :cvlc
    command_style :gnu
  end
 
  class GCC
    include Runnable

    executes :gcc
    command_style :gnu
  end

end
