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
# extends Publisher
# can_fire :stopped

  attr_accessor :pid
  
  # Constructor
  def initialize( *opts, delete_log = true )  
    @command = self.class.to_s.downcase
    
    @options = opts.join( " " )
    @delete_log = delete_log
    
    # @todo: checks that command is in the PATH
    # ...
    
    @pid = nil
    @log_path = "/var/log/runnable/"
  end
  
  # Start the command
  def run
  
    stdin, stdout, stderr, @wait_thread = Open3.popen3( @command + " " + @options )
    
    @pid = @wait_thread.pid
    
    # Check if log directory already exists 
    # If not, the directory is created
    create_log_directory
    
    @out_file = File.open( @log_path + "#{@command}_#{self.pid}.log", "a+" )  
    
    @err_thread = Thread.new do
      stderr.each_line do | line | 
        @out_file.write( "[#{Time.new.inspect} || [STDERR] || [#{@pid}]] #{line}" )
      end
    end
    
    @out_thread = Thread.new do
      stdout.each_line{|line| 
        @out_file.write( "[#{Time.new.inspect} || [STDOUT] || [#{@pid}]] #{line}" )
      }
    end
            
        
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
    @out_thread.join
    @err_thread.join
    @wait_thread.join
    @out_file.close
    
    File.delete(@log_path + "#{@command}_#{self.pid}.log") if delete_log
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
  
  def create_log_directory
    Dir.mkdir(@log_path) unless Dir.exist?(@log_path)
  end  
end
