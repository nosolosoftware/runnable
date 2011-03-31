class Runnable
  attr_reader :pid
  
  def initialize( command )
    @command = command
    
    @pid = nil
  end
  
  def run
    proc = IO.popen( @command )
    @pid = proc.id
  end
  
  def stop
    Process.kill("INT", @pid)
  end
  
  def kill
    Process.kill("KILL", @pid)
  end
  
end
