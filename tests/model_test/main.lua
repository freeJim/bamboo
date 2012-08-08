#!/usr/bin/env lua  
redis = require 'redis'
require 'lglib'


local DB_HOST = '127.0.0.1'
local DB_PORT =  6379
local WHICH_DB = 0
local AUTH = nil
-- create a redis connection in this process
-- we will create one redis connection for every process
local db = redis.connect(DB_HOST, DB_PORT)
assert(db, '[Error] Database connection is failed.')
if AUTH then assert(db:command("auth",AUTH)); end
assert(db:select(WHICH_DB));


BAMBOO_DB = db
require 'bamboo'

-- load file handler_xxx.lua, make its environment as childenv, extract global variables in handler_xxx.lua to childenv
setfenv(assert(loadfile("settings.lua")), setmetatable(bamboo.config, {__index=_G}))()


local Model = require 'bamboo.model'

function field_check(self,field,value)
     local fdt = self.__fields[field];
     assert(fdt ~= nil , "undefine field");

     --required
     assert((fdt.required or false) and (self[field]~=nil),"field value is nil");
     assert((self[field] == nil and value~=nil) or (self[field] ~= nil and value==nil),"the field value is wrong");

     if self[field]==nil and value==nil then
         return;
     end
     
     --type
     if fdt["type"] ~= nil and fdt["type"]=="number" then --number
        assert(type(self[field])=="number", "field not number");
        assert(self[field] == tonumber(value), "field value wrong");
        assert((fdt.min or false) and (self[field]>=fdt.min),"field value invalidate");
        assert((fdt.max or false) and (self[field]<=fdt.max),"field value invalidate");
     else --string
        assert(type(self[field])=="string", "field not string");
        assert(self[field] == value, "field value wrong");
        assert((fdt.min_length or false) and (string.len(self[field])>=fdt.min_length),"field value invalidate");
        assert((fdt.max_length or false) and (string.len(self[field])<=fdt.max_length),"field value invalidate");
     end 

    --enum
    if fdt["enum"] then
        assert(self[field] == value, "field value wrong");
        local flag = false;
        for i,v in ipairs(fdt["enum"]) do
            if v==value then 
                flag = true;
                break;
            end
        end
        assert(flag,"the value invalidate");
    end

    --pattern 
    if fdt["pattern"] then 
        assert(fdt["type"]==nil ,"field define wrong");
        local s,e = string.find(self[field],fdt["pattern"]);
        assert(s and e and s==1 and e==string.len(self[field]), "field pattern is wrong");
    end

end

local Test1 = Model:extend{
    __tag = 'Object.Model.Test1';
	__name = 'Test1';
	__desc = 'Basic Test1 definition.';
	--__indexfd = "name";
	__fields = {
        ['name'] = {required=true}
	};

    init = function (self,t)
        if not t then return self end;

        self.name = t.name;
        self.created_time = os.time();

        return self
    end,

    filed_check = filed_check,
}
bamboo.registerModel(Test1)


local Test = Model:extend{
    __tag = 'Object.Model.Test';
	__name = 'Test';
	__desc = 'Basic user definition.';
--	__indexfd = {name = "string" , score = "number"};
	__fields = {
        ['required'] = {required=true},
		['string'] = { index_type="string",min_length=10,max_length=100},
		['number'] = { index_type="number", type="number", min=10, max=100},
        ['enum'] = {enum={"ENUM1","ENUM2"}},
        ['pattern'] = {pattern=":%d-%d=%d"},

        --foreign
        ["mone"] =  {foreign="Test1", st="ONE"},
        ["mmany"] = {foreign="Test1", st="MANY"},
        ["mlist"] = {foreign="Test1", st="LIST"},
        ["mfifo"] = {foreign="Test1", st="FIFO"},
        ["mzfifo"] ={foreign="Test1", st="ZFIFO"},

        ["uone"] =  {foreign="UNFIXED", st="ONE"},
        ["umany"] = {foreign="UNFIXED", st="MANY"},
        ["ulist"] = {foreign="UNFIXED", st="LIST"},
        ["ufifo"] = {foreign="UNFIXED", st="FIFO"},
        ["uzfifo"] ={foreign="UNFIXED", st="ZFIFO"},

        ["aone"] =  {foreign="ANYSTRING", st="ONE"},
        ["amany"] = {foreign="ANYSTRING", st="MANY"},
        ["alist"] = {foreign="ANYSTRING", st="LIST"},
        ["afifo"] = {foreign="ANYSTRING", st="FIFO", fifolen=5},
        ["azfifo"] ={foreign="ANYSTRING", st="ZFIFO", fifolen=5},
	};

    init = function (self,t)
        if not t then return self end;

        self.name = t.name;
        self.score = t.score;
        self.created_time = os.time();

        return self
    end,

    filed_check = filed_check,
}

bamboo.registerModel(Test)


function testMain()
    Test:all():del();
    Test1:all():del();

    local test = Test();
    test.required = "required",
    test:save();
    
    local id = test1.id;
    test = Test:getById(id);
    assert(test,"model getById() failed");
    test:field_check("id",id)
    test:field_check("required","required")



end


testMain();
print("ALL TESTS PASS")
