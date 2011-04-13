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
      # Expresion regular para comprobar contra la salida de 'ps -A'
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
      
      
      #Recuperamos el contenido del fichero de log      
      my_command_output = []
      
      log = File.open("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log", "r") 
      log.each_line do |line|
        my_command_output.push line.split(" ").last
      end
      log.close
      
      #Recuperamos la salida del comando en el sistema
      system_output = `ls`.split( "\n" )


      system_output.should == my_command_output
    end
    
    it "should print the standard error of the command in a log file" do
      @my_command = LS.new(
         {:command_options => "-invalid_option",
          :delete_log => false})
          
      @my_command.run

      @my_command.join
      
      #Recuperamos el contenido del fichero de log 
      log = File.open("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log", "r") 
      my_command_output = log.read.split( "\n" )[0]
      my_command_output =~ /\[[.]\]\s(\.+)/
      my_command_output = $1
      log.close
      
      #Recuperamos la salida del comando en el sistema
      #La ejecucion del comando para hacer la comprobación
      #saca un error por stderr, que es el que se muestra al
      #ejecutar los tests mediante una terminal
      system_output = `ls -invalid_option`.split( "\n" )[0]

      system_output.should == my_command_output
    end

  end
  describe "managing log files" do
    it "Should delete log files by default" do
      @my_command = BC.new()

      
      @my_command.run
      @my_command.kill

      File.exist?("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log").should be_false
      
    end

    it "should not delete log files if we don't want it explicity" do
      @my_command = BC.new( {:delete_log => false} )

      @my_command.run
      @my_command.kill

      File.exist?("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log").should be_true
      
    end
  end

  describe "controlling exceptions" do
    it "should not return any exceptions array" do
      @my_command = LS.new( {:command_options => '-lah', :delete_log => false} )

      @my_command.when :fail do
        fail
      end
      
      @my_command.when :finish do
        true.should be_true
      end

      @my_command.run
      @my_command.join
    end
    
    it "should return an argument exception" do
      @my_command = LS.new( {:command_options => '-invalid_option', :delete_log => false} )

      @my_command.when :finish do
        fail
      end
      
      @my_command.when :fail do |array|
        array.empty?.should_not be_true
      end

      @my_command.run 
      @my_command.join
    end
  end

end
