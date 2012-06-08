module(..., package.seeall)

local db = BAMBOO_DB

function save()--key, tbl, scores
    return [[
    local function zssave(key,tbl,scores)
        tbl = loadstring("return "..tbl)();

        redis.call("DEL",key);
        if not scores then 
            local n=0;
            for _,v in ipairs(tbl) do 
                redis.call("ZADD",key,n+1,tostring(v));
                n = n + 1;
            end
        else
            scores = loadstring("return "..scores)();
            assert(type(scores)=='table', "[ERROR] scores must be table or nil or false");
            assert(#scores==#tbl, "[ERROR] the length of tbl and scores must be equal");

            for i,v in ipairs(tbl) do 
                local score = scores[i];
                assert(type(tonumber(score))=='number', '[ERROR] The score in score list is not number ')
                redis.call("ZADD",key,score,tostring(v));
            end   
        end

        return 'true'
    end
    ]]
end

function update()--key, tbl
    return [[ 
    local function zsupdate(key,tbl)
        local n = redis.call("ZCARD",key);
        
        tbl = loadstring("return "..tbl)();
        for _,v in ipairs(tbl) do 
            redis.call("ZADD",key,n+1,tostring(v))
            n = n+1;
        end

        return 'true'
    end ]]
end



function add()-- key, member, score 
    return [[
    local function zsadd(key,member,score)
        if not score then
            local n = redis.call("ZCARD",key);
            if n == 0 then 
                score = 1;
            else
                local lastscore = redis.call("ZRANGE",key,-1,-1,'withscores')[2];
                score = lastscore + 1;
            end
        end

        assert(type(tonumber(score))=='number', '[ERROR] The score in score list is not number ');
        redis.call("ZADD",key,score,member);

        return score;
    end ]]

--[[	local oscore = db:zscore(key, val)
	-- is exist, do nothing, else redis will update the score of val
	if oscore then return nil end
	
	if not score then
		-- get the current element in zset
		local n = db:zcard(key)
		if n == 0 then
			db:zadd(key, 1, val)
		else
			local lastscore = db:zrange(key, -1, -1, 'withscores')[1][2]
			-- give the new added element score n+1
			db:zadd(key, lastscore + 1, val)
		end	
	else
		checkType(score, 'number')
		db:zadd(key, score, val)
	end

	-- return the score 
	return db:zscore(key, val)]]
end


function retrieve()-- key 
    return [[
    local function zsretrieve(key)
        return redis.call("ZRANGE",key,0,-1);
    end ]]
end

function retrieveReversely()-- key 
    return [[
    local function zsretrieveReversely(key)
        return redis.call("ZREVRANGE",key,0,-1);
    end ]]
end 

function retrieveWithScores()-- key 
    return [[
    local function zsretrieveWithScores(key)
        return redis.call("ZRANGE",key,0,-1,'withscores');
    end]]
end

function retrieveReverselyWithScores( key )
    return [[
    local function zsretrieveReverselyWithScores(key)
        return redis.call("ZREVRANGE",key,0,-1,'withscores');
    end]]
end

function remove()-- key, member 
    return [[
    local function zsremove(key,member)
        return redis.call("ZREM",key,member);
    end]]
end

function removeByScore()--key, score
    return [[
    local function zsremoveByScore(key,score)
        return redis.call("ZREMRANGEBYSCORE",key,score,score);
    end]]
end

function num()-- key 
    return [[
    local function zsnum(key)
        return redis.call("ZCARD",key);
    end]]
end

function del() --key
    return [[
    local function zsdel(key)
        return redis.call('DEL',key);
    end ]]
end

function fakedel() --key
    return [[
    local function zsfakedel(key)
        return redis.call("RENAME",key,"DELETED:" .. key);
    end ]]
end

function has()--key, member
    return [[
    local function zshas(key,member)
        if redis.call("ZSCORE",key,tostring(member)) == false then
            return 'false';
        else
            return 'true';
        end
    end ]]
end

