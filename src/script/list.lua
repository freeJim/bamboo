-- wapper to redis list structure
-- new is at right, old is at left
module(..., package.seeall)

local db = BAMBOO_DB
local List = require 'lglib.list'

--- create a list
--
function save()--key, tbl 
    return [[ local function lsave(key,tbl)
        if redis.call("EXISTS",key) then
            redis.call("DEL",key);
        end

        tbl = loadstring("return "..tbl)();
        for i,v in ipairs(tbl) do
            redis.call("RPUSH",key,tostring(v));
        end

        return 'true';
    end ]]
end

--- update a list
--
function update()-- key, tbl 
    return [[ local function lupdate(key,tbl)
        local list = redis.call("LRANGE",key,0,-1);
        tbl = loadstring("return "..tbl)();

        if #list >= #tbl then
            for i,v in ipairs(tbl) do 
                if list[i] ~= v then 
                    redis.call("LSET",key,i-1,tostring(v));
                end
            end
            local delta = #list-#tbl;
            for i=1,delta do 
                redis.call("RPOP",key);
            end
        else
            for i,v in ipairs(list) do 
                if tbl[i] ~= v then
                    redis.call("LSET",key,i-1,tostring(tbl[i]));
                end
            end
            local delta = #tbl - #list;
            for i=1,delta do 
                redis.call("RPUSH",key,tostring(tbl[#list+i]));
            end
        end

        return 'true';
    end ]]
end

function retrieve()-- key 
    return [[ local function lretrieve(key)
        return redis.call("LRANGE",key,0,-1);
    end ]]
end

function append()-- key, val 
	return [[ local function lappend(key,val)
        return redis.call("RPUSH",key,tostring(val));
    end ]]
end

function prepend()-- key, val 
	return [[ local function lprepend(key,val)
        return redis.call("LPUSH",key,tostring(val));
    end ]]
end

function pop()-- key 
	return [[ local function lpop(key)
        return redis.call("RPOP",key);
    end ]]
end 

function remove()-- key, val 
	return [[ local function lremove(key,val)
        return redis.call("LREM",key,0,val);
    end ]]
end

function removeByIndex()-- key, index 
    return [[ local function lremoveByIndex(key,index)
        local elem = redis.call("LINDEX",key,tonumber(index))
        if elem then 
            return redis.call("LREM",key,0,elem);
        end
        return 'false';
    end ]]
end

function len()-- key
    return [[ local function llen(key)
        return redis.call("LLEN",key);
    end ]]
end

function del()-- key 
    return [[ local function ldel(key)
        return redis.call("DEL",key);
    end ]]
end

function has()--key, obj
    return [[ local function lhas(key,obj)
        local len = redis.call("LLEN",key);
        for i=0, len-1 do 
            local elem = redis.call("LINDEX",key,i);
            if obj == elem then 
                return 'true';
            end
        end
        return 'false';
    end ]]
end

