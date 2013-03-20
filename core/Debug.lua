__isUnwindingStack = false
function __instrument_class(t, tname)
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

	t.__instrumented_functions = { }
	for fname, f in pairs(t) do
		if type(f) == "function" and not t.__instrumented_functions[fname] then
			local name = ("%s:%s"):format(tname, fname)
			t[fname] = function(...) return __instrument_function(f, name, ...) end
			t.__instrumented_functions[fname] = true
		end
	end
end
