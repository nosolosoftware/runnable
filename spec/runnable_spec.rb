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
      @my_command = BC.new
    end
    
    it "should execute the command in the system" do
      @my_command.run
      
      `ps -A | grep bc`.should match /^((\s)?(\d)+\s([a-zA-Z0-9?\/]*)(\s)+(\d\d:\d\d:\d\d)\sbc)$/
    end
    
    it "should know the pid of the system process" do
      
      @my_command.run

      @my_command.pid.should_not be_nil

      Dir.exist?( "/proc/#{@my_command.pid}" ).should be_true

    end    
  end
  
  describe "sending signals to a blocking process" do
    before( :each ) do
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
