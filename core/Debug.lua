local __isUnwindingStack = false
function __instrument_class(t, tname)
	print (("Instrumenting Class %s"):format(tname))
	local function __instrument_function(f, fname, ...)
		local r
		local p = {...}
		__isUnwindingStack = false
		local s, err = pcall(function() r = {f(unpack(p))} end)
		if not s then
			if not __isUnwindingStack then
				print(("Unhandle error caught:"):format(tostring(err))
				print(("--> %s"):format(fname))
				__isUnwindingStack = true
			else
				print((" in %s"):format(fname))
			end
			error(err)
		end
		return unpack(r)
	end
	for fname, f in pairs(t) do
		if type(f) == "function" then
			local name = ("%s:%s"):format(tname, fname)
			t[fname] =  function(...) return __instrument_function(f, name, ...) end
		end
	end
end
