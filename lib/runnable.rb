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
require 'publisher'

class Runnable
  extend Publisher
  
  can_fire :stopped
  can_fire :finish
  can_fire :fail

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

     # @todo: checks that command is in the PATH
    # ...
    
    @pid = nil
    
    @excep_array = []

    subscribe :stopped do
      prepare_to_close
    end
  end
  
  # Start the command
  def run
    # Check if log directory already exists 
    # If not, the directory is created
    create_log_directory  
  
    stdin, stdout, stderr, @wait_thread = Open3.popen3( @command + " " + @options )
    
    @pid = @wait_thread.pid

    @exit_thread = Thread.new do
      begin
        Process.wait( @pid )
        @exit_status = $?.exitstatus
        
        if @exit_status != 0 then
          @excep_array << SystemCallError.new( @exit_status )
          
          fire :fail, @excep_array
        else
          fire :finish
        end
      rescue Exception
        puts "EXCEPTION!!!!!!"
      end
      
      fire :stopped
    end    
    
    @out_file = File.open( @log_path + "#{@command}_#{self.pid}.log", "a+" )  
    
    @err_thread = Thread.new do
      stderr.each_line do | line |
      
        exceptions.each do | reg_expr, value |
          if reg_expr =~ line then
            @excep_array << value.new( $1 )
          end
        end
       
        @out_file.write( "[#{Time.new.inspect} || [STDERR] || [#{@pid}]] #{line}" )
      end
    end
    
    @out_thread = Thread.new do
      stdout.each_line do | line | 
        @out_file.write( "[#{Time.new.inspect} || [STDOUT] || [#{@pid}]] #{line}" )
      end
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
    # @out_thread.join
    # @err_thread.join
    # @wait_thread.join
    @exit_thread.join
  end
 
  def exceptions
    {}
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

  def prepare_to_close
    # Check possible exceptions
    hash_exp = exceptions 
  
    @out_file.close
    if @delete_log == true
      File.delete(@log_path + "#{@command}_#{self.pid}.log")
    end
  end
end
