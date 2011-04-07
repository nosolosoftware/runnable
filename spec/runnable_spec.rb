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
      #Create and launch the command
      @my_command = Sleep.new( 5 )
      @my_command.run
      
      #The process should be executing
      `ps -A | grep #{@my_command.pid}` =~ @ps_regexp
      
      #Waiting for end of child execution
      @my_command.join
      
      #This should execute only if the child process has exited
      true.should be_true
    end
  end
  
  describe "redirect the stdout and stderr strems" do
    it "should print the output of the command in a log file" do
      @my_command = LS.new()
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
    
    it "should print the standar error of the command in a log file" do
      @my_command = LS.new( "-invalid_option" )
      @my_command.run
      
      @my_command.join
      
      #Recuperamos el contenido del fichero de log 
      log = File.open("/var/log/runnable/#{@my_command.class.to_s.downcase}_#{@my_command.pid}.log", "r") 
      my_command_output = log.read.split( "\n" )[0]
      my_command_output =~ /\[[.]\]\s(\.+)/
      my_command_output = $1
      log.close
      
      #Recuperamos la salida del comando en el sistema
      system_output = `ls -invalid_option`.split( "\n" )[0]

      system_output.should == my_command_output
    end
  end
end
