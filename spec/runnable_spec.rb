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
      Dir.exists?("/proc/#{@my_command.pid}").should be_true
      
      #Ahora comprobamos que la información contenida en el proceso con el
      #PID que nos devuelve la instancia concuerda con lo esperado
      File.open("/proc/#{@my_command.pid}/stat", "r") do | file |
          data = file.read.split( " " )
          data[0].to_i.should == @my_command.pid
          data[1].should == "(#{@my_command.class.to_s.downcase})"          
      end
    end
    
    it "should execute the command in the system" do
      #Creamos la instancia del comando
      @my_command = Yes.new
      
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
      @my_command = DC.new
      
      #Lanzamos el proceso
      @my_command.run
      
      @my_command.pid.should == `ps -A | grep dc`.split(" ")[0].to_i
       
      #Enviamos al proceso la señal de stop
      @my_command.stop
      
      #Ahora el directorio de este proceso no debería existir en la carpeta 
      #/proc
      Dir.exist?("/proc/#{@my_command.pid}").should be_false
    end
    
    it "should be killed when I send a kill signal" do      
      pending
    end
    
    after( :each ) do
      @my_command.kill
    end 
  end
  
  describe "return termination codes" do
    it "should return value 0 if termination was correct" do
      #@my_command = Command.new( "ls -alh" )
      pending
    end
    
    it "should not return a value 0 if termination was incorrect due to invalid parameters" do
      #@my_command = Command.new( "ls -option" )
      pending
    end
  end
  
  describe "return stop signal" do
    it "should return stop signal when execution ends correctly after sometime" do
      pending
    end
  end
end
