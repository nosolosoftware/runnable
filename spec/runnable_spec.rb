require File.expand_path(File.join('.', 'spec_helper'), File.dirname(__FILE__))

describe Runnable do
  describe "creating a command" do
    before( :each ) do
      @my_command = LS.new
    end
    
    # We ensure the instance is created with the appropiates methods
    # defined early
    it "should be able to be runned, stopped and killed" do
      @my_command.should respond_to( :run )      
      @my_command.should respond_to( :stop )
      @my_command.should respond_to( :kill )
    end
    
  end

  describe "running system commands" do
    before( :each ) do
      # Regular expresion used to match the 'ps -A' output
      # $1 indicates the process PID
      # $2 indicates which terminal the process is running on (TTY)
      # $3 indicates the amount of CPU time that the process has been running (TIME)
      # $4 indicates the name of the command
      @ps_regexp = /^\s?(\d+)\s([a-zA-Z0-9?\/]*)\s+(\d+:\d+:\d+)\s(\w+)$/
    end
    
    # Test to confirm that the retrieved PID from instance matches the real
    # process PID in the system 
    it "should know the pid of the system process" do
    
      # Create a new instance of a command
      @my_command = BC.new
      
      # Run the process
      @my_command.run

      # The process PID should be known
      @my_command.pid.should_not be_nil
      
      # And a new directory should be created in the system folder '/proc/'
      # containing all the information refered to our process
      Dir.exists?("/proc/#{@my_command.pid}").should be_true
      
      # We double-check the retreived information against the stat file
      File.open("/proc/#{@my_command.pid}/stat", "r") do | file |
        data = file.read.split( " " )
        data[0].to_i.should == @my_command.pid
        data[1].should == "(#{@my_command.class.to_s.downcase})"          
      end
      
    end
    
    # Test to check if our process instance is really executing a system command
    it "should execute the command in the system" do
      @my_command = BC.new
      @my_command.run
       
      # Look for a system process with the PID retrieved from our instance, 
      # which is assumed to be correct due previous test
      `ps -A | grep #{@my_command.pid}` =~ @ps_regexp
      
      # Confirm if the match is correct cheking the known PID 
      $1.to_i.should == @my_command.pid
      
      # Check if the process name is the same of our command class
      $4.should == @my_command.class.to_s.downcase      
    end
    
    # As we are using blocking commands, we need to terminate the execution
    after( :each ) do
      @my_command.kill
    end  
  end
  
  describe "sending signals to a blocking process" do 
    it "should be stopped when I send a stop signal" do 
      @my_command = BC.new
      @my_command.run
      
      # As our process is running, there should be a directory in folder '/proc'
      # containing all the information related to our process
      Dir.exist?("/proc/#{@my_command.pid}").should be_true
       
      # We send the stop command to our process
      @my_command.stop
      
      # Now that process has been stopped, the system should terminates it
      # and the directory with process information should not exist
      Dir.exist?("/proc/#{@my_command.pid}").should be_false
    end
    
    it "should be killed when I send a kill signal" do      
      # This test is very similar to previous one, we just send the kill signal
      # instead of stop signal
      
      @my_command = BC.new
      @my_command.run
      
      Dir.exist?("/proc/#{@my_command.pid}").should be_true
       
      # We send the kill command to our process
      @my_command.kill
      
      Dir.exist?("/proc/#{@my_command.pid}").should be_false
    end
  end
  
  describe "return termination codes" do
    it "should return value 0 if termination was correct" do
      pending
    end
    
    it "should not return a value 0 if termination was incorrect due to invalid parameters" do
      pending
    end
  end
  
  describe "return stop signal" do
    it "should return stop signal when execution ends correctly after sometime" do
      pending
    end
  end
  
  describe "control the command execution" do
    it "should stop the execution of parent until the child has exit" do
      [0, 1, 3, 6].each do |seconds|
        # Create and launch the command
        @my_command = Sleep.new( {:command_options => seconds} )

        time_before = Time.now
        @my_command.run
        
        # The process should be executing
        `ps -A | grep #{@my_command.pid}` =~ @ps_regexp
        
        # Waiting for end of child execution
        @my_command.join
        time_after = Time.now
        
        # Total seconts difference between both times
        total_time = time_after - time_before

        # This should execute only if the child process has exited
        total_time.round.should == seconds 
      end
    end
  end
  
  describe "redirect the stdout and stderr streams" do
    it "should print the output of the command in a log file" do
      @my_command = LS.new( {:delete_log => false} )
      @my_command.run
      
      @my_command.join
      
      
      # Recover the content of the log file      
      my_command_output = []
      
      log = File.open("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log", "r") 
      log.each_line do |line|
        # Get the last part of each line in the log file
        my_command_output.push line.split(" ").last
      end
      log.close
      
      # Get the system command output
      system_output = `ls`.split( "\n" )

      # System command and log file output should be the same
      system_output.should == my_command_output
    end
    
    it "should print the standard error of the command in a log file" do
      @my_command = LS.new(
         {:command_options => "-invalid_option",
          :delete_log => false})
          
      @my_command.run

      @my_command.join
      
      # Recover the content of the log file 
      my_command_output = []

      log = File.open("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log", "r") 
      log.each_line do |line|
        # Get the non matched part of the line
        line =~ /\[.*\]\s(.+)/
        my_command_output << $1
      end
      log.close
      
      # Get the system command output

      # Get pipes to redirect IO
      rd, wr = IO.pipe

      # Call to command system
      Kernel.system( 'ls -invalid_option', :err => wr )
      wr.close
      
      
      my_command_output.should == rd.read.split( "\n" )
     
    end

  end
  describe "managing log files" do
    it "Should delete log files by default" do
      @my_command = BC.new()

      
      @my_command.run

      # Check that log file exist
      File.exist?("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log").should be_true
 
      @my_command.kill
      # Check if log file is deleted
      File.exist?("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log").should be_false
      
    end

    it "should not delete log files if we don't want it explicity" do
      @my_command = BC.new( {:delete_log => false} )

      @my_command.run
      
      # Check that log file exist
      File.exist?("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log").should be_true

      @my_command.kill
      # Check that log file is removed
      File.exist?("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log").should be_true
      
    end
  end

  describe "controlling exceptions" do
    it "should not return any exceptions array" do
      @my_command = LS.new( {:command_options => '-lah', :delete_log => false} )
      
      # Set what must happen when getting a fire

      # Example should fail if we get a fire :fail
      @my_command.when :fail do
        fail
      end

      # Example should pass when we get a fire :finish
      @my_command.when :finish do
        true.should be_true
      end

      @my_command.run
      @my_command.join
    end
    
    it "should return an argument exception" do
      @my_command = LS.new( {:command_options => '-invalid_option', :delete_log => false} )
      
      # Set what must happen when getting a fire
      
      # if we get a finish publish, it should fail!
      @my_command.when :finish do
        fail
      end
      # if we get a :fail publish, we go throught the good way
      @my_command.when :fail do |array|
        # Exceptions array must not be empty, because we failed :P
        array.empty?.should_not be_true
      end

      @my_command.run 
      @my_command.join
    end
  end

  describe "Controling process internal variables" do
    it "Should return the correct pwd" do
      @my_command = LS.new

      @my_command.run

      my_output= `pwd`.chomp
      
      @my_command.pwd.should be_eql( my_output )
    end

    it "should return the correct command owner" do
      # Owner must be yourself
      @my_command = LS.new

      @my_command.run

      `id`.split( " " )[0] =~ /uid=(\d+)/
      
      @my_command.owner.should be_eql( $1 )
    end


    it "Should return the correct group id" do
      # Group must be YOUR group
      @my_command = LS.new

      @my_command.run

      `id`.split( " " )[1] =~ /gid=(\d+)/

       @my_command.group.should be_eql( $1 )
    end

    it "Should return the memory usage" do
      # Check that match `ps --pid @pid u` with my_command.mem
      @my_command = BC.new

      @my_command.run

      my_mem = `ps --pid #{@my_command.pid} u`.split( "\n" )[1].split( " " )[4].to_i
      
      @my_command.mem.should be_eql( my_mem )


      @my_command.kill

    end

  end

  describe "Control the class method processes" do

    it "Should return the empty hash" do
      # No instances running == empty hash

      BC.processes.should be_empty
    end

    it "Should return the empty hash with no instances running" do
      # Instance created but not running
      @my_command = BC.new

      BC.processes.should be_empty
    end

    it "Should return a no empty hash with one instance" do

      @my_command = BC.new

      @my_command.run

      # the method should return a hash,
      # with @pid as key and the instance as value
      BC.processes[@my_command.pid].should be_equal( @my_command )

      @my_command.kill
    end

    it "Should return a no empty hash with two instances" do

      @my_command = BC.new

      @my_second_instance = BC.new

      @my_command.run

      @my_second_instance.run
      

      BC.processes[@my_command.pid].should be_equal( @my_command )
      
      BC.processes[@my_second_instance.pid].should be_equal( @my_second_instance )

      @my_command.kill
      @my_second_instance.kill

    end

    it "Should not return a instance with an invalid pid" do

      # Invalid pid!!! its random!!!
      BC.processes[10121].should be_nil
    end

  end

  describe "Calculate CPU usage" do
    it "should return the current cpu usage 100%" do
      @my_bc = BC.new( :command_options => "examples_helpers/bc_big_operation" )

      @my_bc.run
      
      sleep 5
      # 100% cpu usage
      my_cpu_usage = `ps --pid #{@my_bc.pid} u`.split( "\n" )[1].split( " " )[2].to_f

      # We want a tolerance of 5%
      @my_bc.cpu.should be_within( 5 ).of( my_cpu_usage )
      @my_bc.kill
      end

    it "Should return the current cpu usage (random)" do
      # We are going to use command line vlc for this example
      @my_vlc = CVLC.new(:command_options => "examples_helpers/song.mp3")

      @my_vlc.run
      # Wait until all is loaded, to avoid different measures
      sleep 2

      my_cpu_usage = `ps --pid #{@my_vlc.pid} u`.split( "\n" )[1].split( " " )[2].to_f

      # We dont really need to be the same
      # but we want to be close ( 5% tolerance )
      @my_vlc.cpu.should be_within( 5 ).of( my_cpu_usage )

      @my_vlc.kill
    end

  end
end
