PRAGMA_ONCE()

local function __init_class_api()
   local function __is_a(o, b)
      local otype = type(o)
      local btype = type(b)
      if otype ~= "table" and btype ~= "table" then
         return otype == btype
      end

      local c_mt = getmetatable(o)
      local c = rawget(c_mt, "__class")
      while not rawequal(c, b) and c ~= nil do
         c = rawget(c, "__base")
      end
      
      return rawequal(c, b)
   end

   local function __init(o, ...)
      if not o or type(o) ~= "table" then return end

      local t = { }
      
      local c_mt = getmetatable(o)
      local c = rawget(c_mt, "__class")
      while c ~= nil do
         local init = rawget(c, "init")
         if init ~= nil and type(init) == "function" then
            table.insert(t, 1, init)
         end
         c = rawget(c, "__base")
      end
      
      for _, init in pairs(t) do
         init(o, ...)
      end
   end

   local function __instrument_recursive(c)
      if not rawget(c, "__instrumented") then
         local base = rawget(c, "__base")
         if base ~= nil then
            __instrument_recursive(base)
         end
         
         local name = rawget(c, "__class_name")
         __instrument_class(c, name)

         rawset(c, "__instrumented", true)
      end
   end

   function class(name, base, init)
      if not init and not base then
         init = nil
         base = nil
      elseif not init and type(base) == 'function' then
         init = base
         base = nil
      elseif type(base) ~= 'table' then
         base = nil
      end

      if init ~= nil and type(init) ~= 'function' then
         init = nil
      end

      local c = { __class_name = name, __instrumented = false }
      local c_mt = { __index = c, __class = c }
      if base ~= nil then
         c.__base = base
         setmetatable(c_mt, { __index = base })
      end

      function c:is_a(b)
         return __is_a(self, b)
      end

      function c:init(...)
         if init ~= nil then
            init(self, ...)
         end
      end

      c_mt.__call = function(_, ...)
         __instrument_recursive(c)
         local o = { }
         setmetatable(o, c_mt)
         __init(o, ...)
         return o
      end

      setmetatable(c, c_mt)
      return c
   end

   return class
end

local class = __init_class_api()
__init_class_api = nil

--[[
function classUnitTests()
   local Test = class("Test", function(self) self.test = 1; print("Constructed") end)
   function Test:Test() print("Hello World! "..tostring(self.test)) end
   function Test:NotDerived() end

   local inst = Test()
   inst:Test()

   local Test2 = class("Test2", Test, function(self) self.test = 2; print("Constructed 2") end)
   function Test2:Test() Test.Test(self); print("Overriden!") end
   
   local inst2 = Test2()
   inst2:Test()

end
classUnitTests()
]]