module(..., package.seeall)
local db = BAMBOO_DB

-- @param tbl:  a member list
function save()--key, tbl
    return [[
    local function ssave(key,tbl)
        tbl = loadstring("return ".. tbl)();
        for _,v in ipairs(tbl) do 
            redis.call("SADD",key,tostring(v));
        end
        return 'true'
    end ]]
end

function update()--key, tbl
    return [[
    local function supdate(key,tbl)
        tbl = loadstring("return ".. tbl)();
        for _,v in ipairs(tbl) do 
            redis.call("SADD",key,tostring(v));
        end
        return 'true'
    end ]]
end

function add()--key, val 
    return [[ 
    local function sadd(key,val)
        return redis.call("SADD",key,val)
    end ]]
end

function retrieve()--key
    return [[
    local function sretrieve(key)
        return redis.call("SMEMBERS",key);
    end ]]
end

function remove()-- key, val 
    return [[
    local function sremove(key,val)
        return redis.call("SREM",key,val);
    end ]]
end

function num()-- key 
	return [[
    local function snum(key)
        return redis.call("SCARD",key);
    end ]]
end

function del()-- key 
	return [[
    local function sdel(key)
        return redis.call("DEL",key);
    end ]]
end

function has()--key, obj
    return [[
    local function shas(key,obj)
        if redis.call("SISMEMBER",key,tostring(obj)) == 1 then 
            return 'true';
        else
            return 'false';
        end
    end ]]
end

