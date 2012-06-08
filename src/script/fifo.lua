-- FIFO, we push element from left, pop from right,
-- new element is at left, old element is at right
module(..., package.seeall)
local db = BAMBOO_DB

function save()--key, tbl, length
    return ""
end

function update() --key, tbl, length
    return ""
end

function push ()--key, val, length
    return [[
    local function fpush(key,val,length)
        local len = redis.call("LLEN",key);
        if len < tonumber(length) then 
            return redis.call("LPUSH",key,val);
        else
            redis.call("RPOP",key);
            return redis.call("LPUSH",key,val);
        end
    end ]]
end

function pop( key )
	return [[ local function fpop(key)
        return redis.call("RPOP",key);
    end ]]
end

function remove( key, val )
	return [[ local function fremove(key,val)
        return redis.call("LREM",key,0,val);
    end ]]
end

function retrieve( key )
    return [[ local function fretrieve(key)
        return redis.call("LRANGE",key,0,-1);
    end ]]
end

function len( key )
    return [[ local function flen(key)
        return redis.call("LLEN",key);
    end ]]
end

function del( key )
    return [[ local function fdel(key)
        return redis.call("DEL",key);
    end ]]
end

function fakedel(key)
    return [[ local function ffakedel(key)
        return redis.call("RENAME",key,'DELETED:'+key);
    end ]]
end

function has(key, obj)
    return [[ local function fhas(key,obj)
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

