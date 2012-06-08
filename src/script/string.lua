module(..., package.seeall)
local db = BAMBOO_DB

-- @param tbl:  a member list
function save()--key, val
    return [[
    local function strsave(key,val)
        return redis.call("SET",key,val);
    end ]]
end

function update()--key ,val
    return [[
    local function strupdate(key,val)
        return redis.call("SET",key,val);
    end ]]
end

function add()--key,val
    return [[
    local function stradd(key,val)
        return redis.call("SET",key,val);
    end ]]
end

function retrieve()--key
    return [[
    local function strretrieve(key)
        return redis.call("GET",key);
    end ]]
end

function remove()--key
    return [[
    local function strremove(key)
        return redis.call("SET",key,'');
    end ]]
end

function num()-- key 
    return [[
    local function strnum(key)
        return 1;
    end ]]
end

function del()-- key 
    return [[
    local function strdel(key)
        return redis.call("DEL",key);
    end ]]
end

function has()--key, obj
    return [[
    local function strhas(key,obj)
        if redis.call("GET",key) == obj then
            return 'true';
        else
            return 'false'
        end
    end ]]
end

