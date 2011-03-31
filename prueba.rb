
proc = Thread.new() do 
	system("sleep 20")
end

system("ls")

proc.join
