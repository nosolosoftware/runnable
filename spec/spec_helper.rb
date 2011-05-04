$LOAD_PATH << File.expand_path( '../../lib', __FILE__ ) 
$LOAD_PATH << File.expand_path( '../../lib/runnable', __FILE__ )
$LOAD_PATH << File.expand_path( '../../examples_helpers', __FILE__ ) 

require 'runnable'

require 'commands'
include Commands

