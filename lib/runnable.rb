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
  def initialize( option_hash= {} )
    # keys :delete_log
    #      :command_options
    #      :log_path
    
    @command = self.class.to_s.downcase
    
    # Set the default command option
    # Empty by default
    option_hash[:command_options] ||= ""
    @options = option_hash[:command_options]
    
    # @todo: checks that command is in the PATH
    # ...
    
    @pid = nil
    
    # Set the log path
    # Default path is "/var/log/runnable"
    option_hash[:log_path] ||= "/var/log/runnable/"
    @log_path = option_hash[:log_path]

    # Set the delete_log option
    # true by default
    if option_hash[:delete_log] == nil
      @delete_log = true
    else 
      @delete_log = option_hash[:delete_log]
    end

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
    prepare_to_close

  end
  
  protected
  
  # Send the desired signal to the command
  # @param [Symbol] signal must be a symbol
  # @todo: @raise exeption
  def send_signal( signal )
    Process.detach( @pid )
    prepare_to_close

    if signal == :stop
      Process.kill( :SIGINT, @pid )
    elsif signal == :kill
      Process.kill( :SIGKILL, @pid )
    end
  end
  
  def create_log_directory
    Dir.mkdir(@log_path) unless Dir.exist?(@log_path)
  end

  def prepare_to_close
    @out_file.close
    if @delete_log == true
      File.delete(@log_path + "#{@command}_#{self.pid}.log")
    end
  end
end
