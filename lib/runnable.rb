# Convert a executable command in a Ruby-like class
# you are able to start, send signals, stop the command
#
# @example usage:
#   class LS < Runnable
#   end
#
#   ls = LS.new
#   ls.start
#
class Runnable
  attr_reader :pid
  
  # 
  def initialize
    @command = self.class.to_s.downcase
    
    # @todo: checks that command is in the PATH
    # ...
    
    @pid = nil
  end
  
  # Start the command
  def run
    IO.popen( @command )
  end
  
  # Stop the command 
  # @return nil
  # @todo: @raise exeption
  def stop
    send_signal( :stop )
  end
  
  # Kill the comand
  # @return nil
  # @todo: @raise exeption
  def kill
    send_signal( :kill )
  end
  
  
  protected
  
  # Send the desired signal to the command
  # @param [Symbol] signal must be a symbol
  # @todo: @raise exeption
  def send_signal( signal )
    if signal == :stop
      Process.kill( :SIGINT, @pid )
    elsif signal == :kill
      Process.kill( :SIGKILL, @pid )
    end
  end  
end
