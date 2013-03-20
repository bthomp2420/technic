function __instrument_class(t, tname)
	print (("Instrumenting Class %s"):format(tname))
	local function __instrument_function(f, fname, ...)
		local r
		local p = {...}
		local s, err = pcall(function() r = {f(unpack(p))} end)
		if not s then
			print(fname)
			error(err)
		end
		return unpack(r)
	end
	for fname, f in pairs(t) do
		if type(f) == "function" then
			local name = ("%s:%s"):format(tname, fname)
			print((" + %s"):format(name))
			t[fname] =  function(...) return __instrument_function(f, fname, ...) end
		end
	end
end
