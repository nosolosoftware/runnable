class Runnable
  attr_reader :pid
  
  def initialize( )
    @command = self.class.to_s.to_lower
    
    # checks that command is in the PATH
    # ...
    
    @pid = nil
  end
  
  def run
    proc = IO.popen( @command )
    @pid = proc.pid
  end
  
  def stop
    Process.kill(:SIGINT, @pid)
  end
  
  def kill
    Process.kill(:SIGKILL, @pid)
  end
  
end
