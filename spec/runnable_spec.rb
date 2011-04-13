require File.expand_path(File.join('.', 'spec_helper'), File.dirname(__FILE__))

describe Runnable do
  describe "creating a command" do
    before( :each ) do
      @my_command = LS.new
    end
    
    it "should be able to be runned, stopped and killed" do
      @my_command.should respond_to( :run )      
      @my_command.should respond_to( :stop )
      @my_command.should respond_to( :kill )
    end
    
  end

  describe "running system commands" do
    before( :each ) do
      # Expresion regular para comprobar contra la salida de 'ps -A'
      # $1 debe ser el PID del proceso
      # $2 debe ser el TTY
      # $3 debe ser el TIME
      # $4 debe ser el nombre del comando CMD
      @ps_regexp = /^\s?(\d+)\s([a-zA-Z0-9?\/]*)\s+(\d+:\d+:\d+)\s(\w+)$/
    end
    
    it "should know the pid of the system process" do
      #Creamos la instancia del comando
      @my_command = BC.new
      
      #Lanzamos el proceso
      @my_command.run

      #Comprobamos que existe el directorio de nuestro proceso en la
      #carpeta /proc

      @my_command.pid.should_not be_nil
      Dir.exists?("/proc/#{@my_command.pid}").should be_true
      
      #Ahora comprobamos que la información contenida en el proceso con el
      #PID que nos devuelve la instancia concuerda con lo esperado
      File.open("/proc/#{@my_command.pid}/stat", "r") do | file |
          data = file.read.split( " " )
          data[0].to_i.should == @my_command.pid
          #data[1].should == "(#{@my_command.class.to_s.downcase})"          
      end
    end
    
    it "should execute the command in the system" do
      #Creamos la instancia del comando
      @my_command = BC.new
      
      #Lanzamos el proceso
      @my_command.run
       
      #Comprobamos que existe un proceso en el sistema con el pid devuelto
      #que asumimos como correcto gracias al test anterior
      `ps -A | grep #{@my_command.pid}` =~ @ps_regexp
      
      #Comprobamos que el pid devuelto es el mismo por el que preguntamos
      $1.to_i.should == @my_command.pid
      #Comprobamos que el nombre del proceso es el correcto
      $4.should == @my_command.class.to_s.downcase      
    end
    
    after( :each ) do
      @my_command.kill
    end  
  end
  
  describe "sending signals to a blocking process" do 
    it "should be stopped when I send a stop signal" do 
      #Creamos la instancia del comando
      @my_command = BC.new
      
      #Lanzamos el proceso
      @my_command.run
      
      @my_command.pid.should == `ps -A | grep #{@my_command.pid}`.split(" ")[0].to_i
      Dir.exist?("/proc/#{@my_command.pid}").should be_true
       
      #Enviamos al proceso la señal de stop
      @my_command.stop
      
      #Ahora el directorio de este proceso no debería existir en la carpeta 
      #/proc
      Dir.exist?("/proc/#{@my_command.pid}").should be_false
    end
    
    it "should be killed when I send a kill signal" do      
      #Creamos la instancia del comando
      @my_command = BC.new
      
      #Lanzamos el proceso
      @my_command.run
      
      @my_command.pid.should == `ps -A | grep #{@my_command.pid}`.split(" ")[0].to_i
      Dir.exist?("/proc/#{@my_command.pid}").should be_true
       
      #Enviamos al proceso la señal de stop
      @my_command.kill
      
      #Ahora el directorio de este proceso no debería existir en la carpeta 
      #/proc
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
      [0, 1, 3, 6].each { |seconds|

        #Create and launch the command
        @my_command = Sleep.new( {:command_options => seconds} )

        time_before = Time.now
        @my_command.run
        
        #The process should be executing
        `ps -A | grep #{@my_command.pid}` =~ @ps_regexp
        
        #Waiting for end of child execution
        @my_command.join
        time_after = Time.now
        
        # Total seconts difference between both times
        total_time = time_after - time_before

        #This should execute only if the child process has exited
        total_time.round.should == seconds 
      }
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
        line =~ /\[[.]\]\s(\.+)/
        my_command_output.push $1
      end
      log.close
      
      # Get the system command output
      # This execution print in stderr
      # the error code which is seen
      # when test are executed
      system_output = `ls -invalid_option`.split( "\n" )

      system_output.should == my_command_output
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

end
