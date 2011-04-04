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
    send_signal( :stop )
  end
  
  def kill
    send_signal( :kill )
  end
  
  
  protected
  
  def send_signal( signal )
    if signal == :stop
      Process.kill( :SIGINT, @pid )
    elsif signal == :kill
      Process.kill( :SIGKILL, @pid )
    end
  end  
end
