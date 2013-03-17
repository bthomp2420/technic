function SaveTable(file, t)
	local data = serialize(t)
	local f = fs.open(file, "w")
	if f ~= nil then
		f.write(data)
		f.close()
		return true
	end
	return false
end

function LoadTable(file)
	local result
	if fs.exists(file) then
		local f = fs.open(file, "r")
		if f ~= nil then
			local fd = f.readAll()
			local chunk = loadstring(fd)
			if chunk ~= nil then
				result = chunk()
			end
			f.close()
		end
	end
	return result
end