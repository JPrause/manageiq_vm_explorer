def getSvnInfo
	ret = {}
	pipe = IO.popen("svn info")
	while x = pipe.gets
		if x.include?(":")
			y = x.split(":")
			ret[y[0].downcase] = y[1..-1].join(":").strip
		end
	end
	ret
end

File.open("revision.svn", "w+") {|f| f << getSvnInfo['revision']}