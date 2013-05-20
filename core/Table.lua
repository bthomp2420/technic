PRAGMA_ONCE()

function BeginSaveTable(file, t)
	-- read on the old data and save it in a buffer
	local fileBak = file..".bak"
	fs.delete(fileBak)

	-- if the file already exists copy it
	if fs.exists(file) then
		fs.copy(file, fileBak)
	end

	-- write out the new data and then return a completion function
	local f = fs.open(file, "w")
	if f ~= nil then
		local data = serialize(t)
		f.write(data)
		f.close()

		return function(cancel)	
			if cancel then
				fs.delete(file)
				if fs.exists(fileBak) then
					fs.move(fileBak, file)
				end
				return false
			else
				fs.delete(fileBak)
				return true
			end
		end
	end

	return false
end

function SaveTable(file, t, comment)
	local data = serialize(t)
	local f = fs.open(file, "w")
	if f ~= nil then
		if comment and type(comment) == "string" then
			f.write("-- "..comment:gsub("\n", "\n-- ").."\n\n")
		end
		f.write(data)
		f.close()
		return true
	end
	return false
end

function LoadTable(file)
	local result
	if fs.exists(file) then
		Assert(not fs.exists(file..".bak"), "Saved data is in inconsistent state due to incomplete transaction: %s", file)

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