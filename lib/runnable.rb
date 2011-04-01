class Runnable
  attr_reader :pid
  
  def initialize( command )
    @command = command
    
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
