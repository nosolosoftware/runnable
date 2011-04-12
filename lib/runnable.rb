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

require 'rubygems'
require 'publisher'

class Runnable

  extend Publisher
  
  can_fire :fail, :finish
  
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
    #End of initialize instance variables
    
    
    create_log_directory
  end
  
  # Start the command
  def run    
    @run_thread = Thread.new do
      out_rd, out_wr = IO.pipe
      err_rd, err_wr = IO.pipe
      
      @pid = Process.spawn( "#{@command} #{@options}", { :out => out_wr, :err => err_wr } )
      
      log = File.open( "#{@log_path}#{@command}_#{@pid}.log", "a+" )

      out_thread = Thread.new do
        out_wr.close

        out_rd.each_line do | line |
          log.write( "[#{Time.new.inspect} || [STDOUT] || [#{@pid}]] #{line}" )
        end
      end

      err_thread = Thread.new do
        err_wr.close

        err_rd.each_line do | line |
          exceptions.each do | reg_expr, value |
            if reg_expr =~ line then
              @excep_array << value.new( $1 )
            end
          end
        
          log.write( "[#{Time.new.inspect} || [STDERR] || [#{@pid}]] #{line}" )
        end
      end

      out_thread.join
      err_thread.join

      log.close
      delete_log
      
      Process.wait( @pid, Process::WUNTRACED )
      
      exit_status = $?.exitstatus
      
      if exit_status != 0
        @excep_array << SystemCallError.new( exit_status )
      end
      
      if @excep_array.empty? then
        fire :finish
      else
        fire :fail, @excep_array
      end
      
      Process.detach( @pid )
    end
    
    #Funcion uberguarra que nos permite que todo funcione
    while(@pid == nil)
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
    @run_thread.join
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
  
  
  def delete_log
    if @delete_log == true
      File.delete( "#{@log_path}#{@command}_#{@pid}.log" )
    end
  end  
end
