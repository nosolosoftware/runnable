require File.expand_path(File.join('.', 'spec_helper'), File.dirname(__FILE__))

describe Runnable do
  describe "creating a command" do
    before( :each ) do
      @my_command = Command.new( "ls" )
    end
    
    it "should be able to be runned" do
      @my_command.should respond_to(:run)      
    end
  end


  describe "running system commands" do
  
    before( :each ) do
      @my_command = Command.new( "ls" )
    end
    
    it "should execute the command in the system" do
      #Comprobar que el comando se ejecuta sobre el sistema
      
      pending 
    end
    
    it "should know the pid of the system process" do
      #Comprobar que se almacena el pid y que es el correspondiente 
      #al proceso que se ejecuto
      
      pending 
    end    
  end
  
  describe "sending signals to a blocking process" do
    before( :each ) do
      @my_command = Command.new( "grep" )
      @my_command.run
    end
  
    it "should be stopped when I send a stop signal" do
      #Comprobar que el proceso se para y se queda en el estado correcto
      #@my_command.stop
      
      pending
    end
    
    it "should be killed when I send a kill signal" do
      #Comprobar que el proceso se destruye y se queda en el estado correcto
      #@my_command.kill
      
      pending
    end
  end
end
