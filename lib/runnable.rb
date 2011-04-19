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
  
  attr_reader :pid, :owner, :group, :pwd
  #attr_writer :input, :output

  # Class variable to store all instances
  @@processes = Hash.new

  # Constant to calculate cpu usage
  HERTZ = 100

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

    # Store input options
    @input = Array.new

    # Store outpur options
    @output = Array.new

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
    out_rd, out_wr = IO.pipe
    err_rd, err_wr = IO.pipe

    @pid = Process.spawn( "#{@command} #{@input.join( " " )} #{@options} #{@output.join( " " )}", { :out => out_wr, :err => err_wr } )

    # Include instance in class variable
    @@processes[@pid] = self

    # Prepare the file to be read
    file_status = File.open( "/proc/#{@pid}/status" ).read.split( "\n" )
    # Owner: Read the owner of the process from /proc/@pid/status
    @owner = file_status[6].split( " " )[1]
    # Group: Read the Group owner from /proc/@pid/status
    @group = file_status[7].split( " " )[1]
   

    create_logs(:out => [out_wr, out_rd], :err => [err_wr, err_rd])
    


    @run_thread = Thread.new do
      Process.wait( @pid, Process::WUNTRACED )

      @output_threads.each{ |thread| thread.join }
      delete_log

      exit_status = $?.exitstatus
      
      if exit_status != 0
        @excep_array << SystemCallError.new( exit_status )
      end
      
      if @excep_array.empty? then
        fire :finish
      else
        fire :fail, @excep_array
      end

      # This instance is finished and we remove it
      @@processes.delete( @pid )
    end
    
    # Satuts Variables
    # PWD: Current Working Directory get by /proc/@pid/cwd
    begin
      @pwd = File.readlink( "/proc/#{@pid}/cwd" )
    rescue
      # If cwd is not available rerun @run_thread
      if @run_thread.alive?
        #If it is alive, we retry to get cwd
        @run_thread.run
        retry
      else
        #If process has terminated, we set pwd to current working directory of ruby
        @pwd = Dir.getwd
      end
    end


  end
  
  # Stop the command 
  # @return nil
  # @todo: @raise exeption
  def stop
    send_signal( :stop )

    # In order to maintain consistency of @@processes
    # we must assure that @run_thread finish correctly
    @run_thread.run if @run_thread.alive?
  end
  
  # Kill the comand
  # @return nil
  # @todo: @raise exeption
  def kill
    send_signal( :kill )

    # In order to maintain consistency of @@processes
    # we must assure that @run_thread finish correctly
    join
  end
  
  def join
    @run_thread.join if @run_thread.alive?
  end

  # Calculate the estimated memory usage in Kb
  # @return Number
  def mem
    File.open( "/proc/#{@pid}/status" ).read.split( "\n" )[11].split( " " )[1].to_i
  end

  # Calculate the estimated CPU usage in %
  # @return Number
  def cpu
    # Open the proc stat file
    begin
      stat = File.open( "/proc/#{@pid}/stat" ).read.split
      
      utime = stat[13].to_f
      stime = stat[14].to_f
      start_time = stat[21].to_f
      
      uptime = File.open( "/proc/uptime" ).read.split[0].to_f
      
      total_time = utime + stime # in jiffies 

      seconds = uptime - ( start_time / HERTZ ) 
      # Not so cool expresion
      #( ( total_time.to_f * 1000 / HERTZ ) / seconds.to_f ) / 10
      # Cool expression
      (total_time / seconds.to_f)
    rescue Exception
      # if we reach here there was an exception
      # we return 0 either we rescue an ENOENT or ZeroDivisionError
      0
    end

  end

  # Method to set the input file
  def input ( param )
    @input << param
  end

  # Method to set the output file
  def output ( param )
    @output << param
  end

  # Class method
  # return a hash of processes with all the instances running
  def self.processes
    @@processes
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
    if signal == :stop
      Process.kill( :SIGINT, @pid )
    elsif signal == :kill
      Process.kill( :SIGKILL, @pid )
    end
  end
  
  def create_logs(outputs = {})
    FileUtils.touch "#{@log_path}#{@command}_#{@pid}.log" # Create an empty file for logging

    @output_threads = []
    outputs.each do |output_name, pipes|
      @output_threads << Thread.new do
        pipes[0].close

        pipes[1].each_line do |line|
          File.open("#{@log_path}#{@command}_#{@pid}.log", "a") do |log_file|
            log_file.puts( "[#{Time.new.inspect} || [STD#{output_name.to_s.upcase} || [#{@pid}]] #{line}" )
          end

          exceptions.each do | reg_expr, value |
            if reg_expr =~ line then
              @excep_array << value.new( $1 )
            end
          end
        end
      end
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
