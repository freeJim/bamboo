module(..., package.seeall)

local db = BAMBOO_DB

function save()
    return [[
    local function zfsave()
        return ""
    end ]]
end

function update()
    return [[
    local function zfupdate()
        return ""
    end ]]
end


function push()-- key, val, length 
    return [[
    local function zfpush(key, val, length)
        local n = redis.call("ZCARD",key);

        if n<tonumber(length) then 
            if n==0 then 
                redis.call("ZADD",key,1,val);
            else
                local lastscore = redis.call("ZRANGE",key,-1,-1,'withscores')[2];
                redis.call("ZADD",key,lastscore+1, val);
            end
        else
            local lastscore = redis.call("ZRANGE",key,-1,-1,'withscores')[2];
            redis.call("ZREMRANGEBYRANK",key,0,0);
            redis.call("ZADD",key,lastscore+1, val);
        end
    end ]]
end

function pop()-- key
    return [[
    local function zfpop(key)
        local n = redis.call("ZCARD",key);
        if n>=1 then
            local it = redis.call("ZRANGE",key,0,0,'withscores');
            local score = it[2];
            redis.call("ZREMRANGEBYRANK",key,0,0);
            return score;
        else
            return 'nil';
        end
    end ]]
end

function remove()-- key, val 
    return [[
    local function zfremove(key,member)
        return redis.call("ZREM",key,member);
    end]]
end

function removeByScore()--key, score
    return [[
    local function zfremoveByScore(key,score)
        return redis.call("ZREMRANGEBYSCORE",key,score,score);
    end]]
end


function retrieve()-- key 
    return [[ 
    local function zfretrieve(key)
        return redis.call("ZREVRANGE",key,0,-1);
    end ]]
end

function retrieveWithScores()--key
    return [[
    local function zfretrieveWithScores( key)
        return redis.call("ZREVRANGE",key,0,-1,'withscores');
    end ]]
end 

function num( key )
    return [[
    local function zfnum(key)
        return redis.call("ZCARD",key);
    end]]
end

function del( key )
    return [[
    local function zfdel(key)
        return redis.call('DEL',key);
    end ]]
end

function fakedel()--key
    return [[
    local function zffakedel( key)
        return redis.call("RENAME",key, 'DELETED:'+key);
    end ]]
end

function has()--key, obj
    return [[
    local function zfhas(key,member)
        local ret = redis.call("ZSCORE",key,tostring(member));
        if redis.call("ZSCORE",key,tostring(member)) == false then
            return 'false';
        else
            return 'true'
        end
    end ]]
end
