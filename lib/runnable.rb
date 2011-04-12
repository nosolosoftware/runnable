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
  
#  attr_accessor :pid
  
  # Constructor
  # @param [Hash] option_hash Options
  # @option option_hash :delete_log (true) Delete the log after execution
  # @option option_hash :command_options ("") Command options
  # @option option_hash :log_path ("/var/log/runnable") Path for the log files
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
    @pid_mutex = Mutex.new
    @run_thread = Thread.new do
      out_rd, out_wr = IO.pipe
      err_rd, err_wr = IO.pipe

      @pid_mutex.synchronize {
        @pid = Process.spawn( "#{@command} #{@options}", { :out => out_wr, :err => err_wr } )
      }

      create_logs(:out => [out_wr, out_rd], :err => [err_wr, err_rd])
      
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
    end
  end
  
  def pid
    Thread.new { 
      Thread.pass
      @pid_mutex.lock 
    }.join if @pid == nil
    return @pid
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
 
  # @abstract Should be overwritten
  def exceptions
    {}
  end
  
  protected
  
  # Send the desired signal to the command
  # @param [Symbol] signal must be a symbol
  # @todo: @raise exeption
  def send_signal( signal )
    Process.detach( pid )

    if signal == :stop
      Process.kill( :SIGINT, pid )
    elsif signal == :kill
      Process.kill( :SIGKILL, pid )
    end
  end
  
  def create_logs(outputs = {})
    FileUtils.touch "#{@log_path}#{@command}_#{pid}.log" # Create an empty file for logging

    @output_threads = []
    outputs.each { |output_name, pipes|
      @output_threads << Thread.new do
        pipes[0].close

        pipes[1].each_line do |line|
          File.open("#{@log_path}#{@command}_#{pid}.log", "a") do |log_file|
            log_file.puts( "[#{Time.new.inspect} || [STD#{output_name.to_s.upcase} || [#{pid}]] #{line}" )
          end

          exceptions.each do | reg_expr, value |
            if reg_expr =~ line then
              @excep_array << value.new( $1 )
            end
          end
        end
      end
    }

    @output_threads.each{ |thread| thread.join }

    delete_log
  end


  def create_log_directory
    Dir.mkdir(@log_path) unless Dir.exist?(@log_path)
  end
  
  
  def delete_log
    if @delete_log == true
      File.delete( "#{@log_path}#{@command}_#{pid}.log" )
    end
  end  
end
