function GetAPI()
	local function download(user, name, path)
		if not fs.exists(path) then
			local data = http.get(('https://raw.github.com/%s/%s/master/%s'):format(self.user, self.name, path))
			local h = fs.open(path, 'w')
			local text = data.readAll()
			h.write(text)
			h.close()
		end
	end

	fs.makeDir("apis")
	GitHubRawGet("eric-wieser", "computercraft-github", "apis/dkjson")
	GitHubRawGet("eric-wieser", "computercraft-github", "apis/github")

	fs.makeDir("programs")
	GitHubRawGet("eric-wieser", "computercraft-github", "programs/github")

	return dofile("apis/github")
end

-- clone the repository
GetAPI().repo("bthomp2420", "technic"):cloneTo("", function(item) end)

-- startup
shell.run("Init.lua")