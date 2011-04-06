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

require 'open3'

class Runnable
  attr_accessor :pid
  
  # 
  def initialize( *opts )  
    @command = self.class.to_s.downcase
    
    @options = opts
    
    # @todo: checks that command is in the PATH
    # ...
    
    @pid = nil
  end
  
  # Start the command
  def run 
    raise NoMethodError if RUBY_VERSION < "1.9.1"
    
    sin, sout, serr, @wait_thread = Open3.popen3( @command + " " + @options[0].to_s )

    @pid = @wait_thread[:pid]   
    
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
  
  def join
    @wait_thread.join()
  end
  
  protected
  
  # Send the desired signal to the command
  # @param [Symbol] signal must be a symbol
  # @todo: @raise exeption
  def send_signal( signal )
    Process.detach( @pid )
    
    if signal == :stop
      Process.kill( :SIGINT, @pid )
    elsif signal == :kill
      Process.kill( :SIGKILL, @pid )
    end
  end  
end
