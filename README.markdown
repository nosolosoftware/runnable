# Runnable
A Ruby gem that allow programmer to control UNIX system commands as a Ruby class.

# Usage
All you have to do is to create a class named exactly as command and make it 
inherit from class Runnable.

    class LS
      include Runnable
    end

That gives you the basics to control the execution of ```ls``` command.
You can overwrite the name of the command by using the ```executes``` macro:

    class MyLs
      include Runnable

      executes :ls
    end

Now you can create an instance like this:

    my_command = LS.new

And run the command as follows

    my_command.run

Many other options are available; you can stop the command, kill it or look 
for some important information about the command and its process. Entire 
documentation of this gem can be generated using ```yardoc```. To do this use 
```rake doc```.

## Custom output and exceptions
Runnable parse a set of user defined regular expresion to set up the command return
values.

This is an example of how we can receive the return value of a command:

    class Nmap
      include Runnable
      
      executes :nmap

      define_command( :scan, :blocking => true ) { |ip, subnet| "-sP #{ip}/#{subnet}" }
      scan_processors(
        :exceptions => { /^Illegal netmask value/ => ArgumentError },
        :outputs => { /Nmap scan report for (.*)/ => :ip }
      )
    end

    Nmap.new.scan("192.168.1.1", "24") # should return an array with the ips

Runnable can also raise custom exceptions, using the previously Nmap defined class:
    Nmap.new.scan("192.168.1.1", "1000")
Will raise an ArgumentError exception.
Note that Runnable will also raise an exception if the command returned value is not 0.

## Background usage
Runnable can be used with background process:

    class Ping
      include Runnable

      define_command( :goping, :blocking => false) { "-c5 www.google.es" }

      goping_processors(
        :outputs => { /64 bytes from .* time=(.*) ms/ => :time  }
      )
    end

    p = Ping.new
    p.goping

    while p.running?
      p p.output[:time]
      sleep 1
    end

# About
Runnable is a gem developed by [NoSoloSoftware](http://nosolosoftware.biz).

# License
Runnable is Copyright 2011 NoSoloSoftware, it is free software.

Runnable is distributed under GPLv3 license. More details can be found at COPYING
file.  

