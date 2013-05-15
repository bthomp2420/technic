PRAGMA_ONCE()

function BeginSaveTable(file, t)
	local oldData
	local data = serialize(t)
	if fs.exists(file) then
		local f = fs.open(file, "r")
		if f ~= nil then
			oldData = f.readAll()
			f.close()
		end
	end
	local f = fs.open(file, "w")
	if f ~= nil then
		f.write(data)
		return function(cancel)
			f.close()
			if cancel then
				if oldData ~= nil then
					local f2 = fs.open(file, "w")
					if f2 ~= nil then
						f2.write(oldData)
						f2.close()
					end
				else
					fs.delete(file)
				end
			end
			return cancel == false
		end
	end
	return function(cancel) return false end
end

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