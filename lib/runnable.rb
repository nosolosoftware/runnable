# Convert a executable command in a Ruby-like class
# you are able to start, define params and send signals (like kill, or stop)
#
# @example usage:
#   class LS < Runnable
#     command_style :extended
#   end
#
#   ls = LS.new
#   ls.alh
#   ls.run
#

require 'publisher'

class Runnable
  extend Publisher
  
  # Fires to know whats happening inside
  can_fire :fail, :finish

  # Basic Instance Variables
  attr_reader :pid, :owner, :group, :pwd
  
  # Metaprogramming part of the class
  # Template to set the command line parameters
  def self.command_style( style )
    define_method( :command_style ) do
      style
    end
  end
  
  # In case the user didn't define a command_style
  # we assume gnu style
  def command_style
    :gnu
  end

  # Class variable to store all instances
  # order by pid
  @@processes = Hash.new

  # Constant to calculate cpu usage
  HERTZ = 100

  # Initializer method
  # @param [Hash] option_hash Options
  # @option option_hash :delete_log (true) Delete the log after execution
  # @option option_hash :command_options ("") Command options
  # @option option_hash :log_path ("/var/log/runnable") Path for the log files
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
    @input = Array.new

    # Store output options
    @output = Array.new

    # @todo: checks that command is in the PATH
    # ...
    
    # we dont set the pid, because we dont know until run
    @pid = nil
    @excep_array = []
    

    # Metaprogramming part
    # Require the class to parse the command line options
    require command_style.to_s.downcase
    # Create a new instance of the parser class
    @command_line_interface = Object.const_get( command_style.to_s.capitalize.to_sym ).new
    # End Metaprogramming part
   
    #End of initialize instance variables
   
    create_log_directory
  end
  
  # Start the execution of the command
  # @return [nil]
	# @fire :finish
	# @fire :fail
	def run
    # Create a new mutex
    @pid_mutex = Mutex.new

    # Create pipes to redirect Standar I/O
    out_rd, out_wr = IO.pipe
    # Redirect Error I/O
    err_rd, err_wr = IO.pipe

    # 
    @pid = Process.spawn( "#{@command} #{@input.join( " " )} \
                         #{@options} #{@command_line_interface.parse} \
                         #{@output.join( " " )}", { :out => out_wr, :err => err_wr } )

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
      
      # Fire signals according to the exit code
      if @excep_array.empty?
        fire :finish
      else
        fire :fail, @excep_array
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
  
  # Stop the command 
  # @return [nil]
  # @todo: @raise exeption
  def stop
    send_signal( :stop )

    # In order to maintain consistency of @@processes
    # we must assure that @run_thread finish correctly
    @run_thread.run if @run_thread.alive?
  end
  
  # Kill the comand
  # @return [nil]
  # @todo: @raise exeption
  def kill
    send_signal( :kill )

    # In order to maintain consistency of @@processes
    # we must assure that @run_thread finish correctly
    join
  end
  
  # Wait to @run_thread, wich is the command main thread
	# @return [nil]
  def join
    @run_thread.join if @run_thread.alive?
  end

  # Calculate the estimated memory usage in Kb
  # @return [Number] Estimated mem usage in Kb
  def mem
    File.open( "/proc/#{@pid}/status" ).read.split( "\n" )[11].split( " " )[1].to_i
  end

  # Calculate the estimated CPU usage in %
  # @return [Number] The estimated cpu usage
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

  # Method to set the input files
	# @param [String] param Input to be parsed as command options (must be a string)
	# @return [nil]
  def input( param )
    @input << param
  end

  # Method to set the output files
	# @param [String] param Output to be parsed as command options (must be a string)
	# @return [nil]
  def output( param )
    @output << param
  end

  # This function convert undefined methods (ruby-like syntax) into parameters
  # to be parse at the execution time.
  #
  # This only convert methods with zero or one parameters. A hash can be passed
  # and each key will define a new method and method name will be ignored.
  #
  # find.depth                                         #=> find -depth
  # find.iname( '"*.rb"')                              #=> find -iname "*.rb"
  # find.foo( { :iname => '"*.rb"', :type => '"f"' } ) #=> find -iname "*.rb" - type "f"
  #
  # Invalid method
  # sleep.5 #=> Incorrect
  # "5" is not a valid call to a ruby method so method_missing will not be invoked and will
  # raise a tINTEGER exception
  # 
	# @param [Symbol] method Method called that is missing
	# @param [Array] params Params in the call
	# @param [Block] block Block code in method
	# @return [nil]
  # @overwritten
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

  # Class method
  # return a hash of processes with all the instances running
  # @return [Hash] Pid_and_instances options
	#
	# @options Pid_and_instances pid [Symbol] Process pid
	# @options Pid_and_instances instance [Runnable] Process instance
	# 
  def self.processes
    @@processes
  end
 
  # @abstract Should be overwritten in child clases
	# @return [Hash] Custom_exceptions options
	# @options Custom_exceptions regexp [Regexp] Regexp to match with output error
	# @options Custom_exceptions exception [Exception] Exception to be raised if a positive match happen
	def exceptions
    {}
  end
  
  protected
  
  # Send the desired signal to the command
  # @param [Symbol] signal must be a symbol
  # @todo: @raise ESRCH if pid is not in system
  # or EPERM if pid is not from user
  def send_signal( signal )
    if signal == :stop
      Process.kill( :SIGINT, @pid )
    elsif signal == :kill
      Process.kill( :SIGKILL, @pid )
    end
  end
  
	# Redirect command I/O to log files
	# these files are located in /var/log/runnable
	# @param [Hash] outputs options
	# @options outputs stream [Symbol] stream name
	# @options outputs pipes [IO] I/O stream to be redirected
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

        pipes[1].each_line do |line|
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
	# forcing method misssing to be called
  def parse_hash( hash )
    hash.each do |key, value|
      # Call to a undefined method which trigger overwritten method_missing
      # unless its named as a runnable method
      self.public_send( key.to_sym, value ) unless self.respond_to?( key.to_sym )
    end
  end
end
