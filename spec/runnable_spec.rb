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
      @my_command.run
    end
    
    it "should know the pid of the system process"    
  end
  
  describe "sending signals to a blocking process" do
    before( :each ) do
      @my_command = Command.new( "grep" )
      @my_command.run
    end
  
    it "should be stopped when I send a stop signal" do
      @my_command.stop
    end
    
    it "should be killed when I send a kill signal" do
      @my_command.kill
    end
  end
end
