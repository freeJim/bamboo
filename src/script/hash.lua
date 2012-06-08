module(..., package.seeall)
local db = BAMBOO_DB

function save()--key, tbl
    return [[ 
    local function hsave(key,tbl)
        if redis.call("EXISTS",key) then
            redis.call("DEL",key);
        end

        tbl = loadstring("return ".. tbl)();
        for k,v in pairs(tbl) do
            redis.call("HSET",key,k,tostring(v));
        end
        return 'true';
    end ]];
end

function update()-- key, tbl
    return [[ 
    local function hupdate(key,tbl)
        tbl = loadstring("return ".. tbl)();
        for k,v in pairs(tbl) do
            redis.call("HSET",key,k,tostring(v));
        end
        return 'true';
    end ]];
end

function retrieve()--key
    return [[ 
    local function hretrieve(key)
        return redis.call("HGETALL",key);
    end ]];
end

function add()--key, tbl
    return [[ 
    local function hadd(key,tbl)
        tbl = loadstring("return ".. tbl)();
        for k,v in pairs(tbl) do
            redis.call("HSET",key,k,tostring(v));
        end
        return 'true';
    end ]];
end

function remove()--key,field 
    return [[ 
    local function hremove(key,field)
        return redis.call("HDEL",key,field);
    end ]];
end

function has()--key, field
    return [[ 
    local function hhas(key,field)
        if redis.call("HGET",key,field) then
            return 'true';
        else
            return 'false';
        end
    end ]];
end

function num()--key
    return [[ 
    local function hnum(key)
        return redis.call("HLEN",key);
    end ]];
end
