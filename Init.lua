local context = getfenv()

local __FILE__ = "Init.lua"
local __include_stack = { __FILE__ }
local __pragma_once = { [__FILE__] = true }
local __pragma_once_result = { [__FILE__] = nil }

function PRAGMA_ONCE()
	if not __pragma_once[__FILE__] then
		__pragma_once[__FILE__] = true
		return
	end
	error(__pragma_once)
end

local __session_start_time = os.clock()
local __session_id = math.floor(__session_start_time)
local __log_file_path = ("log_session_%d"):format(__session_id)
local __log_disk_full = false

local k_level_assert = -1
local k_level_message = 0
local k_level_critical = 1
local k_level_error = 2
local k_level_warning = 3
local k_level_info = 4
local k_level_verbose = 10

local __log_level_console = k_level_critical
local __log_level_file = k_level_error

function Log(level, formatString, ...)
	if level > __log_level_file and level > __log_level_console then
		return
	end

	if type(formatString) ~= "string" then
		Log(k_level_error, "Invalid format string provided.")
		return
	end

	local msg
	local args = { ... }
	local success, err = pcall(function() msg = formatString:format(unpack(args)) end)
	if not success then
		if err ~= nil then
			Log(k_level_error, "Error with format string: %s", tostring(err))
			Log(k_level_error, "%s", formatString)
		else
			Log(k_level_error, "Error with format string:")
			Log(k_level_error, "%s", formatString)
		end
		return
	end

	local ts = textutils.formatTime(os.time(), false)
	local output = ("[%s] %s"):format(ts, msg)

	if level <= __log_level_file then
		local remaining = fs.getFreeSpace(__log_file_path)
		local len = strlen(output)
		if remaining < len + 128 and not __log_disk_full then
			local diskFullMessage = ("[%s] disk full"):format(ts)
			if remaining > 128 then	
				local f = fs.open(__log_file_path, "a")
				if f ~= nil then
					f.write(diskFullMessage)
					f.write("\n")
					f.close()
				end
			end
			print(diskFullMessage)
			__log_disk_full = true
		else
			__log_disk_full = false
		end
	end

	if level <= __log_level_file and not __log_disk_full then
		local f = fs.open(__log_file_path, "a")
		if f ~= nil then
			f.write(output)
			f.write("\n")
			f.close()
		end
	end

	if level <= __log_level_console then
		print(output)
	end

	if level == k_level_assert then
		error(output)
	end
end

function Message(f, ...) Log(k_level_message, f, ...) end
function Critical(f, ...) Log(k_level_critical, f, ...) end
function Error(f, ...) Log(k_level_error, f, ...) end
function Warning(f, ...) Log(k_level_warning, f, ...) end
function Info(f, ...) Log(k_level_info, f, ...) end
function Verbose(f, ...) Log(k_level_verbose, f, ...) end
function Assert(condition, f, ...)
	if condition == false then
		Log(k_level_assert, f, ...)
	end
end

function EnsureDirectory(file)
	if file == nil or type(file) ~= "string" then
		return false
	end

	local fileLen = strlen(file)
	local fname = fs.getName(file)
	local fnameLen = strlen(fname) + 1
	if fnameLen < fileLen then
		return fs.makeDir(strlower(strsub(file, 1, fileLen - fnameLen)))
	end

	return true
end

function LoadConfig(file, d)
	local r = nil
	local f, e = loadfile(file)
	if f ~= nil then
		r = f()
	end

	if r == nil and d ~= nil then
		local dType = type(d)
		if dType == "table" then
			r = d
		elseif dType == "function" then
			r = d()
		end

		if r ~= nil and type(r) == "table" then
			EnsureDirectory(file)
			SaveTable(file, r)
		else
			r = nil
		end
	end

	if r == nil then
		r = { }
	end

	return r
end

function Include(file)
	local result
	local included = false
	if fs.exists(file) then
		local f = fs.open(file, "r")
		if f ~= nil then
			local data = f.readAll()
			f.close()

			local chunk = loadstring(data, file)
			if chunk ~= nil then
				table.insert(__include_stack, file)
				__FILE__ = __include_stack[#__include_stack]
				
				Message("+ %s", file)
				local success, err = pcall(function() result = setfenv(chunk, context)() or true end)
				if not success then
					if not rawequal(err, __pragma_once) then
						Error("Failed to include %s: %s", file, tostring(err))
					else
						result = __pragma_once_result[__FILE__]
						included = true
					end
				else
					if __pragma_once[__FILE__] then
						__pragma_once_result[__FILE__] = result
					end
					included = true
				end

				table.remove(__include_stack, #__include_stack)
				__FILE__ = __include_stack[#__include_stack]
			else
				Error("Failed to load %s...", file)
			end
		end
	end
	return result, included
end

function Require(file)
	local result, success = Include(file)
	Assert(success, "Failed to include file: %s", file)
	return result
end

Require("core/Serialize.lua")
Require("core/Debug.lua")
Require("core/Class.lua")
Require("core/Table.lua")

Require("core/TurtleDriver.lua")
local driver = TurtleDriver()

Require("core/TurtleExecutor.lua")
local executor = TurtleExecutor()
for i, file in ipairs(fs.list("modules")) do
	local result = Include(fs.combine("modules", file))
	if executor:AddHandler(result) then
		Message("Loading Module %s", file)
	end
end

executor:Run(driver)