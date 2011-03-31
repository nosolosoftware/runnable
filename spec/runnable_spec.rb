require File.expand_path(File.join('.', 'spec_helper'), File.dirname(__FILE__))

describe Runnable do
  describe "running blocking process" do
    before( :each ) do
      @system = mock( 'System_mock' )
      
      @command = Command.new( @system )
    end
    
    it "should be stopped when no running called" do
      @command.status.should == :stopped
    end
    
    it "should have state running and correct PID when the precces has been runned" do
      @system.should_received(:run_process).and_return(1234)
      
      @command.run
      @command.pid.should == 1234
      
      @command.status.should == :running
    end
  end
end
