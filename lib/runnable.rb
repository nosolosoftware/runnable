# Copyright 2011 NoSoloSoftware

# This file is part of Runnable.
# 
# Runnable is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Runnable is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Runnable.  If not, see <http://www.gnu.org/licenses/>.


require 'runnable/gnu'
require 'runnable/extended'
require 'fileutils'

# Convert a executable command in a Ruby-like class
# you are able to start, define params and send signals (like kill, or stop)
#
# @example Usage:
#   class LS < Runnable
#     command_style :extended
#   end
#
#   ls = LS.new
#   ls.alh
#   ls.run
class Runnable  
  # Process id.
  attr_reader :pid
  # Process owner.
  attr_reader :owner
  # Process group.
  attr_reader :group
  # Directory where process was called from.
  attr_reader :pwd

  # Input file
  attr_accessor :input

  # Set the output file
  attr_accessor :output

  # Metaprogramming part of the class
  
  # Define the parameter style to be used.
  # @return [nil]
  def self.command_style( style )
    define_method( :command_style ) do
      style
    end
  end
  
  # Parameter style used for the command.
  # @return [Symbol] Command style.
  def command_style
    :gnu
  end

  # List of runnable instances running on the system order by pid.
  @@processes = Hash.new

  # Constant to calculate cpu usage.
  HERTZ = 100

  # Create a new instance of a runnable command.
  # @param [Hash] option_hash Options.
  # @option option_hash :delete_log (true) Delete the log after execution.
  # @option option_hash :command_options ("") Command options.
  # @option option_hash :log_path ("/var/log/runnable") Path for the log files.
  def initialize( option_hash = {} )
    # keys :delete_log
    #      :command_options
    #      :log_path
    
    # If we have the command class in a namespace, we need to remove
    # the namespace name
    @command = self.class.to_s.split( "::" ).last.downcase
    
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
    @input = String.new

    # Store output options
    @output = String.new

    # Standar Outputs
    @std_output = {
      :out => "",
      :err => ""
      }

    # @todo: checks that command is in the PATH
    # ...
    
    # we dont set the pid, because we dont know until run
    @pid = nil
    @excep_array = []
    

    # Metaprogramming part  
    # Create a new instance of the parser class
    @command_line_interface = Object.const_get( command_style.to_s.capitalize.to_sym ).new
    # End Metaprogramming part
   
    #End of initialize instance variables
   
    create_log_directory
  end
  
  # Start the execution of the command.
  # @return [nil]
  def run
    # Create a new mutex
    @pid_mutex = Mutex.new

    # Create pipes to redirect Standar I/O
    out_rd, out_wr = IO.pipe
    # Redirect Error I/O
    err_rd, err_wr = IO.pipe
   
    # Reset exceptions array to not store exceptions for
    # past executions
    @excep_array = []

    # Set up the command line
    command = []          
    command << @command
    command << @input
    command << @options
    command << @command_line_interface.parse
    command << @output
    command = command.join( " " )

    @pid = Process.spawn( command, { :out => out_wr, :err => err_wr } )
    
    # Include instance in class variable
    @@processes[@pid] = self

    # Prepare the process info file to be read
    file_status = File.open( "/proc/#{@pid}/status" ).read.split( "\n" )
    # Owner: Read the owner of the process from /proc/@pid/status
    @owner = file_status[6].split( " " )[1]
    # Group: Read the Group owner from /proc/@pid/status
    @group = file_status[7].split( " " )[1]
   
    # Set @output_thread with new threads
    # wich execute the input/ouput loop
    create_logs(:out => [out_wr, out_rd], :err => [err_wr, err_rd])
    
    # Create a new thread to avoid blocked processes
    @run_thread = Thread.new do
      # Wait to get the pid process even if it has finished
      Process.wait( @pid, Process::WUNTRACED )

      # Wait each I/O thread
      @output_threads.each { |thread| thread.join }
      # Delete log if its necesary
      delete_log

      # Get the exit code from command
      exit_status = $?.exitstatus
      
      # In case of error add an Exception to the @excep_array
      @excep_array << SystemCallError.new( exit_status ) if exit_status != 0
      
      # Call methods according to the exit code
      if @excep_array.empty?
        finish
      else
        failed( @excep_array )
      end
      
      # This instance is finished and we remove it
      @@processes.delete( @pid )
    end
    
    # Satuts Variables
    # PWD: Current Working Directory get by /proc/@pid/cwd
    # @rescue If a fast process is runned there isn't time to get
    # the correct PWD. If the readlink fails, we retry, if the process still alive
    # until the process finish.
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
  
  # Stop the command.
  # @return [nil]
  # @todo Raise an exception if process is not running.
  def stop
    send_signal( :stop )

    # In order to maintain consistency of @@processes
    # we must assure that @run_thread finish correctly
    @run_thread.run if @run_thread.alive?
  end
  
  # Kill the comand.
  # @return [nil]
  # @todo Raise an exeption if process is not running.
  def kill
    send_signal( :kill )

    # In order to maintain consistency of @@processes
    # we must assure that @run_thread finish correctly
    join
  end
  
  # Wait for command thread to finish it execution.
  # @return [nil]
  def join
    @run_thread.join if @run_thread.alive?
  end

  # Check if prcess is running on the system.
  # @return [Bool] True if process is running, false if it is not.
  def running?
    Dir.exists?( "/proc/#{@pid}") 
  end

  # Standar output of command
  # @return [String] Standar output
  def std_out
    @std_output[:out]
  end

  # Standar error output of the command
  # @return [String] Standar error output
  def std_err
    @std_output[:err]
  end

  # Calculate the estimated memory usage in Kb.
  # @return [Number] Estimated mem usage in Kb.
  def mem
    File.open( "/proc/#{@pid}/status" ).read.split( "\n" )[11].split( " " )[1].to_i
  end

  # Estimated CPU usage in %.
  # @return [Number] The estimated cpu usage.
  def cpu
    # Open the proc stat file
    begin
      stat = File.open( "/proc/#{@pid}/stat" ).read.split
      
      # Get time variables
      # utime = User Time
      # stime = System Time
      # start_time = Time passed from process starting
      utime = stat[13].to_f
      stime = stat[14].to_f
      start_time = stat[21].to_f
      
      # uptime = Time passed from system starting
      uptime = File.open( "/proc/uptime" ).read.split[0].to_f
      
      # Total time that the process has been executed
      total_time = utime + stime # in jiffies

      # Seconds passed between start the process and now
      seconds = uptime - ( start_time / HERTZ ) 
      # Percentage of used CPU ( ESTIMATED )
      (total_time / seconds.to_f)
    rescue IOError
      # Fails to open file
      0
    rescue ZeroDivisionError
      # Seconds is Zero!
      0
    end

  end

  # Estimated bandwidth in kb/s.
  # @param [String] iface Interface to be scaned.
  # @param [Number] sample_time Time passed between samples in seconds.
  #   The longest lapse the more accurate stimation.
  # @return [Number] The estimated bandwidth used.
  def bandwidth( iface, sample_lapse = 0.1 )
    file = "/proc/#{@pid}/net/dev"
    File.open( file ).read =~ /#{iface}:\s+(\d+)\s+/
    init = $1.to_i
    
    sleep sample_lapse

    File.open( file ).read =~ /#{iface}:\s+(\d+)\s+/
    finish = $1.to_i

    (finish - init)*(1/sample_lapse)/1024
  end

  # Convert undefined methods (ruby-like syntax) into parameters
  # to be parsed at the execution time.
  # This only convert methods with zero or one parameters. A hash can be passed
  # and each key will define a new method and method name will be ignored.
  # 
  # @example Valid calls:
  #   find.depth                                         #=> find -depth
  #   find.iname( '"*.rb"')                              #=> find -iname "*.rb"
  #   find.foo( { :iname => '"*.rb"', :type => '"f"' } ) #=> find -iname "*.rb" - type "f"
  # @example Invalid calls:
  #   sleep.5 #=> Incorrect. "5" is not a valid call to a ruby method so method_missing will not be invoked and will
  #   raise a tINTEGER exception
  # 
  # @param [Symbol] method Method called that is missing
  # @param [Array] params Params in the call
  # @param [Block] block Block code in method
  # @return [nil]
  def method_missing( method, *params, &block )
    if params.length > 1
      super( method, params, block )
    else
      if params[0].class == Hash
        # If only one param is passed and its a Hash
        # we need to expand the hash and call each key as a method with value as params
        # @see parse_hash for more information
				parse_hash( params[0] )
      else
        @command_line_interface.add_param( method.to_s,
                                          params != nil ? params.join(",") : nil )
      end
    end
  end

  # List of runnable instances running on the system.
  # @return [Hash] Using process pids as keys and instances as values.
  def self.processes
    @@processes
  end
 
  # @abstract 
  # Returns a hash of regular expressions and exceptions associated to them.
  # Command output is match against those regular expressions, if it does match
  # an appropiate exception is included in the return value of execution. 
  # @note This method should be overwritten in child classes.
  # @example Usage:
  #   class ls < Runnable
  #     def exceptions
  #       { /ls: (invalid option.*)/ => ArgumentError }
  #     end
  #   end
  #
  # @return [Hash] Using regular expressions as keys and exceptions that should
  #   be raised as values.
	def exceptions
    {}
  end
  
  # @abstract
  # Method called when command ends with no erros.
  # This method is a hook so it should be overwritten in child classes.
  # @return [nil]
  def finish
  end

  # @abstract
  # Method called when command executions fail.
  # This method is a hook so it should be overwritten in child classes.
  # @param [Array] exceptions Array containing exceptions raised during the command execution.
  # @return [nil]
  def failed( exceptions )
  end
  
  # Send the desired signal to the command.
  # @param [Symbol] Signal to be send to the command.
  # @todo raise ESRCH if pid is not in system
  #   or EPERM if pid is not from user.
  def send_signal( signal )      
    if signal == :stop
      signal = :SIGINT
    elsif signal == :kill
      signal = :SIGKILL
    end
    
    `ps -ef`.each_line do |line|
      line = line.split
      pid = line[1]
      ppid = line[2]
     
      if ppid.to_i == @pid
        Process.kill( signal, pid.to_i )
      end
    end
    
    begin
      Process.kill( signal, @pid )
    rescue Errno::ESRCH
      # As we kill child processes, main process may have exit already
    end
  end

  protected
  # Redirect command I/O to log files.
  # These files are located in /var/log/runnable.
  # @param [Hash] Outputs options.
  # @option outputs stream [Symbol] Stream name.
  # @option outputs pipes [IO] I/O stream to be redirected.
  # @return [nil]
  def create_logs( outputs = {} )
    # Create an empty file for logging
    FileUtils.touch "#{@log_path}#{@command}_#{@pid}.log"

    @output_threads = []
    # for each io stream we create a thread wich read that 
    # stream and write it in a log file
    outputs.each do |output_name, pipes|
      @output_threads << Thread.new do
        pipes[0].close

        @std_output[output_name] = ""

        pipes[1].each_line do |line|
          @std_output[output_name] << line

          File.open("#{@log_path}#{@command}_#{@pid}.log", "a") do |log_file|
            log_file.puts( "[#{Time.new.inspect} || [STD#{output_name.to_s.upcase} || [#{@pid}]] #{line}" )
          end
          # Match custom exceptions
          # if we get a positive match, add it to the exception array
          # in order to inform the user of what had happen
          exceptions.each do | reg_expr, value |
  					@excep_array<< value.new( $1 ) if reg_expr =~ line
          end
        end
      end
    end
  end
  
  def create_log_directory
    Dir.mkdir( @log_path ) unless Dir.exist?( @log_path )
  end
  
  def delete_log
    File.delete( "#{@log_path}#{@command}_#{@pid}.log" ) if @delete_log == true
  end

  # Expand a parameter hash calling each key as method and value as param
  # forcing method misssing to be called.
  # @param [Hash] hash Parameters to be expand and included in command execution
  # @return [nil]
  def parse_hash( hash )
    hash.each do |key, value|
      # Add the param parsed to command_line_interface
      @command_line_interface.add_param( 
        key.to_s,
        value != nil ? value.to_s : nil 
        )
    end
  end
end
