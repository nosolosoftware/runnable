# Runnable
A Ruby gem that allow programmer to control UNIX system commands as a Ruby class.

# Usage
All you have to do is to create a class named exactly as command and make it inherit from class Runnable.

```ruby
class LS < Runnable
end
```

That gives you the basics to control the execution of `ls` command.

Now you can create an instance like this:
```ruby
my_command = LS.new
```

And run the command as follows
```ruby
my_command.run
```

Many other options are available; you can stop the command, kill it or look 
for some important information about the command and its process. Entire 
documentation of this gem can be found under `./doc` directory or been generated 
by `yardoc`.

## Return values
Runnable uses another gems called `Publisher`. It allow Runnable to fire 
events that can be processed or ignored. When a command ends its execution, 
Runnable always fire and event: `:finish` if commands finalized in a correct way 
or `:fail` if an error ocurred. In case something went wrong and a `:fail` 
events was fired, Runnable also provide an array containing the command return 
value as the parameter of a SystemCallError exception and optionally others 
exceptions ocurred at runtime.

This is an example of how can we receive the return value of a command:
```ruby
class LS < Runnable
end

my_command = LS.new

my_command.when :finish do
  puts "Everything went better than expected :)"
end

my_command.when :fail do |exceptions|
  puts "Something went wrong"
  exceptions.each do |exception|
    puts exception.message
  end
end

my_command.run
```

## Custom exceptions
As we saw in previous chapter, if a command execution does not ends 
succesfully, Runnable fires a `:fail` event whit an exceptions array. We can
add exceptions to that array based on the output of command. For example, we 
can controll that parameters passed to a command are valids if we know the 
command output for an invalid parameters.

First we have to do is override the method `exceptions` defined in runnable
as follows

```ruby
class LS < Runnable
  def exceptions
    { /ls: (invalid option.*)/ => ArgumentError }
  end
end
```

`exceptions` method should return a hash containing a regular expression 
which will be match against the command output, and a value which will be the
exception added to exception array. This means that if the command output match
the regular expression, a new exception will be include in `:fail` event parameter.

# About
Runnable is a gem develop by [NoSoloSoftware](http://nosolosoftware.biz)

# License
Runnable is Copyright 2011 NoSoloSoftware, it is free software.

Runnable is distributed under GPLv3 license. More details can be found at COPYING
file.  

