function __instrument_class(t, tname)
	print (("Instrumenting Class %s"):format(tname))
	local function __instrument(f, fname, ...)
		local r
		local p = {...}
		local s, o = pcall(function() r = {f(unpack(p))} end)
		if not s then
			print(fname)
			error(o)
		end
		return unpack(r)
	end

	for fname, v in pairs(t) do
		if type(v) == "function" then
			local name = ("%s:%s"):format(tname, fname)
			print((" + %s"):format(name))
			t[fname] = __instrument(v, name)
		end
	end
end
