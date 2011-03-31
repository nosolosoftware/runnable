class Runnable
  attr_accessor :status, :pid
  
  def initialize( system )
    @system = system
    
    @status = :stopped
  end
  
  def run
    @pid = @system.run_process
  
    @status = :running if @status == :stopped
  end
  
end
