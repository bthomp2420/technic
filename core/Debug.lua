function __instrument_class(t, tname)
	local __isUnwindingStack = false

	print (("Instrumenting Class %s"):format(tname))
	local function __instrument_function(f, fname, ...)
		__isUnwindingStack = false

		local r
		local p = {...}
		local s, e = pcall(function() r = {f(unpack(p))} end)
		if not s then
			if not __isUnwindingStack then
				if e then
					print(("Error: %s"):format(tostring(e))
				else
					print("Error: <unknown error>")
				end
				print(("--> %s"):format(fname))
				__isUnwindingStack = true
			else
				print((" in %s"):format(fname))
			end
			error(e)
		end
		
		return unpack(r)
	end

	for fname, f in pairs(t) do
		if type(f) == "function" then
			local name = ("%s:%s"):format(tname, fname)
			t[fname] = function(...) return __instrument_function(f, name, ...) end
		end
	end
end
