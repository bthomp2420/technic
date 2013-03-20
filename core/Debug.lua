function instrument(t, tname)
	print(("Instrumenting Class %s").format(tname))
	local function __instrument(f, fname, ...)
		local r
		local p = pack(...)
		local s, o = pcall(function() r = pack(f(upack(p))) end)
		if not s then
			print(fname)
			error(o)
		end
		return unpack(r)
	end

	for fname, v in ipairs(t) do
		if type(v) == "function" then
			local name = ("%s:%s").format(tname, fname)
			print((" + %s").format(name))
			t[fname] = __instrument(v, name)
		end
	end
end
