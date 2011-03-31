$LOAD_PATH << File.expand_path('../lib/', __FILE__)
 
require 'runnable'

class Command < Runnable

  def initialize( command )
    super( command )
  end
  
end
