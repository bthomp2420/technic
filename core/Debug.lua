local __isUnwindingStack = false

function __instrument_class(t, tname)
	print(("Instrumenting Class %s"):format(tname))
	local function __instrument_function(f, fname, ...)
		local result
		local args = { ... }

		__isUnwindingStack = false
		local success, err = pcall(function() result = { f(unpack(args)) } end)
		if not success then
			if not __isUnwindingStack then
				__isUnwindingStack = true

				if err then
					print(("Error: %s"):format(tostring(err)))
				else
					print("Error: <unknown error>")
				end

				print(("--> %s"):format(fname))
				error(err)
			else
				print((" in %s"):format(fname))
				error(err)
			end
		end

		return unpack(result)
	end

	for fname, f in pairs(t) do
		if type(f) == "function" then
			local name = ("%s:%s"):format(tname, fname)
			print(("+ %s"):format(name))
			t[fname] = function(...) return __instrument_function(f, name, ...) end
		end
	end
end
