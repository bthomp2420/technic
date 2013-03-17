function GetAPI()
	local function download(user, name, path)
		if not fs.exists(path) then
			local data = http.get(('https://raw.github.com/%s/%s/master/%s'):format(user, name, path))
			local h = fs.open(path, 'w')
			local text = data.readAll()
			h.write(text)
			h.close()
		end
	end

	fs.makeDir("apis")
	download("eric-wieser", "computercraft-github", "apis/dkjson")
	download("eric-wieser", "computercraft-github", "apis/github")

	fs.makeDir("programs")
	download("eric-wieser", "computercraft-github", "programs/github")

	return dofile("apis/github")
end

-- clone the repository
GetAPI().repo("bthomp2420", "technic"):cloneTo("", function(item) end)

-- startup
shell.run("Init.lua")