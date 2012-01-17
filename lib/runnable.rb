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
#   class LS 
#     include Runnable
#
#     executes :ls
#     command_style :extended
#   end
#
#   ls = LS.new
#   ls.alh
#   ls.run
module Runnable  
  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    # Define the command to be executed
    # @return [nil]
    # @param [Symbol] command Command to be executed
    def executes( cmd )
      define_method( :command ) { cmd }
    end
 
    # Define the parameter style to be used.
    # @return [nil]
    def command_style( style )
      define_method( :command_style ) { style }
    end
 
    # Create a user definde command
    # @return [nil]
    # @param [Symbol] name The user defined command name
    # @param [Hash] options Options.
    # @option options :blocking (false) Describe if the execution is blocking or non-blocking
    # @option options :log_path (false) Path used to store logs # (dont store logs if no path specified)
    def define_command( name, opts = {}, &block )
      blocking = opts[:blocking] || false
      log_path = opts[:log_path] || false

      commands[name] = { :blocking => blocking }

      define_method( name ) do |*args|
        run name, block.call(*args), log_path
        join if blocking
      end
    end
 
    # Generic command processor. It allows to define generic processors used in all the
    # user defined commands
    # @param [Hash] opts Processing options
    # @option opts :outputs (nil) Output processing Hash (regexp => output)
    # @option opts :exceptions (nil) Exceptions processing Hash (regexp => exception)
    def processors( opts = nil )
      if opts.is_a? Hash
        @processors = opts
      else
        @processors ||= Hash.new
      end
    end

    # Method missing processing for the command processors
    def method_missing( name, *opts )
      raise NoMethodError.new( name.to_s ) unless name.to_s =~ /([a-z]*)_([a-z]*)/
 
      # command_processors
      if $2 == "processors"
        commands[$1.to_sym][:outputs] = opts.first[:outputs]
        commands[$1.to_sym][:exceptions] = opts.first[:exceptions]
      end
    end

    # @group Accessors for the module class variables
 
    # Returns the user defined commands
    # @return [Hash] commands User defined commands
    def commands
      @commands ||= Hash.new
    end
 
    # Returns the list of runnable instances by pid
    # @return [Hash] list of runnable instances by pid
    def processes
      @processes ||= Hash.new
    end

    # Processes writer
    def processes=( value )
      @processes = value
    end
  end
  
  # Process id.
  attr_reader :pid
  # Process owner.
  attr_reader :owner
  # Process group.
  attr_reader :group
  # Directory where process was called from.
  attr_reader :pwd

  # Process output
  attr_reader :output

  # Process options
  attr_accessor :options
  # Process log output
  attr_accessor :log_path

  # Metaprogramming part of the class

  # Parameter style used for the command.
  # @return [Symbol] Command style.
  def command_style
    :gnu
  end

  # Default command to be executed
  # @return [String] Command to be executed
  def command
    self.class.to_s.split( "::" ).last.downcase
  end

  # Constant to calculate cpu usage.
  HERTZ = 100

  # Start the execution of the command.
  # @return [nil]
  def run(name = nil, opts = nil, log_path = nil)
    return false if @pid
    # Create a new mutex
    @pid_mutex = Mutex.new
    
    # Log path should be an instance variable to avoid a mess
    @log_path = log_path || @log_path

    # Create pipes to redirect Standar I/O
    out_rd, out_wr = IO.pipe
    # Redirect Error I/O
    err_rd, err_wr = IO.pipe

    # Reset exceptions array to not store exceptions for
    # past executions
    command_argument = opts ? opts.split(" ") : compose_command

    @pid = Process.spawn( command.to_s, *command_argument, { :out => out_wr, :err => err_wr } )

    # Include instance in class variable
    self.class.processes[@pid] = self

    # Prepare the process info file to be read
    file_status = File.open( "/proc/#{@pid}/status" ).read.split( "\n" )
    # Owner: Read the owner of the process from /proc/@pid/status
    @owner = file_status[6].split( " " )[1]
    # Group: Read the Group owner from /proc/@pid/status
    @group = file_status[7].split( " " )[1]

    # Set @output_thread with new threads
    # wich execute the input/ouput loop
    stream_info = {
      :out => [out_wr, out_rd],
      :err => [err_wr, err_rd]
    }

    if name
      cmd_info = self.class.commands[name]
      stream_processors = {
        :outputs => cmd_info[:outputs],
        :exceptions => cmd_info[:exceptions]
      }
    end

    output_threads = process_streams( stream_info, stream_processors )

    # Create a new thread to avoid blocked processes
    @run_thread = threaded_process(@pid, output_threads)

    # Satuts Variables
    # PWD: Current Working Directory get by /proc/@pid/cwd
    # @rescue If a fast process is runned there isn't time to get
    # the correct PWD. If the readlink fails, we retry, if the process still alive
    # until the process finish.

    begin
      @pwd ||= File.readlink( "/proc/#{@pid}/cwd" )
    rescue Errno::ENOENT
      # If cwd is not available rerun @run_thread
      if @run_thread.alive?
        #If it is alive, we retry to get cwd
        @run_thread.run
        retry
      else
        #If process has terminated, we set pwd to current working directory of ruby
        @pwd = Dir.getwd
      end
    rescue #Errno::EACCESS
      @pwd = Dir.getwd
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
    @output unless @output.empty?
  end

  # Check if prcess is running on the system.
  # @return [Bool] True if process is running, false if it is not.
  def running?
    Dir.exists?( "/proc/#{@pid}") 
  end

  # Standar output of command
  # @return [String] Standar output
  def std_out
    @std_out ||= ""
  end

  # Standar error output of the command
  # @return [String] Standar error output
  def std_err
    @std_err ||= ""
  end

  # Sets the command input to be passed to the command execution
  # @param [String] opt Command input
  def input=( opt )
    @command_input = opt
  end

  # Sets the command output to be passed to the command execution
  # @param [String] opt Command output
  def output=( opt )
    @command_output = opt
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
    @command_line_interface ||= Object.const_get( command_style.to_s.capitalize.to_sym ).new

    if params.length > 1
      super( method, params, block )
    else
      if params[0].class == Hash
        # If only one param is passed and its a Hash
        # we need to expand the hash and call each key as a method with value as params
        # @see parse_hash for more information
				parse_hash( params[0] )
      else
        @command_line_interface.add_param( method.to_s, params != nil ? params.join(",") : nil )
      end
    end
  end

  # List of runnable instances running on the system.
  # @return [Hash] Using process pids as keys and instances as values.
  def self.processes
    @@processes
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
  # Process the command I/O.
  # These files are located in /var/log/runnable.
  # @param [Hash] Outputs options.
  # @option outputs stream [Symbol] Stream name.
  # @option outputs pipes [IO] I/O stream to be redirected.
  # @return [Array] output_threads Array containing the output processing threads
  def process_streams( output_streams = {}, stream_processors = nil )
    @output = Hash.new
    @std_output = Hash.new

    output_threads = []
    # for each io stream we create a thread wich read that 
    # stream and write it in a log file
    output_streams.collect do |output_name, pipes|
      threaded_output_processor(output_name, pipes, stream_processors)
    end
  end
  
  # Expand a parameter hash calling each key as method and value as param
  # forcing method misssing to be called.
  # @param [Hash] hash Parameters to be expand and included in command execution
  # @return [nil]
  def parse_hash( hash )
    hash.each do |key, value|
      # Add the param parsed to command_line_interface
      @command_line_interface.add_param( key.to_s, value != nil ? value.to_s : nil )
    end
  end

  private

  def save_log(output_name, line)
    Dir.mkdir( @log_path ) unless Dir.exist?( @log_path )

    File.open("#{@log_path}/#{self.command}_#{@pid}.log", "a") do |log_file|
      log_file.puts( "[#{Time.new.inspect} || [STD#{output_name.to_s.upcase} || [#{@pid}]] #{line}" )
    end
  end

  def compose_command
    @command_line_interface ||= Object.const_get( command_style.to_s.capitalize.to_sym ).new

    [ @command_input.to_s, 
      @options.to_s, 
      @command_line_interface.parse, 
      @command_output.to_s 
    ].select do |value|
      !value.to_s.strip.empty?
    end.flatten.select{|x| !x.empty?}
  end

  def threaded_process(pid, output_threads)
    Thread.new do
      # Wait to get the pid process even if it has finished
      Process.wait( pid, Process::WUNTRACED )

      # Wait each I/O thread
      output_threads.each { |thread| thread.join }

      # Get the exit code from command
      exit_status = $?.exitstatus

      # This instance is finished and we remove it
      self.class.processes.delete( pid )
      @pid = nil

      # In case of error add an Exception to the @excep_array
      raise SystemCallError.new( exit_status ) if exit_status != 0
    end
  end

  def threaded_output_processor(output_name, pipes, stream_processors)
    exception_processors = stream_processors.is_a?(Hash) ? stream_processors[:exceptions] : {}
    exception_processors.merge!(self.class.processors[:exceptions] || {})

    output_processors = stream_processors.is_a?(Hash) ? stream_processors[:outputs] : {}
    output_processors.merge!(self.class.processors[:output] || {})
        
    Thread.new do
      pipes[0].close

      pipes[1].each_line do |line|
        ( output_name == :err ? self.std_err : self.std_out ) << line

        save_log(output_name, line) if @log_path
        
        # Match custom exceptions
        # if we get a positive match, raise the exception
        exception_processors.each do | reg_expr, value |
          raise value.new( line ) if reg_expr =~ line
        end
         
        # Match custom outputs
        # if we get a positive match, add it to the outputs array
        output_processors.each do | reg_expr, value |
          @output[value] ||= Array.new
          @output[value] << $1 if reg_expr =~ line
        end

      end
    end
  end
  
end
