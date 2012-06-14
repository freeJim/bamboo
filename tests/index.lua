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
local Model = require 'bamboo.model'


local Test = Model:extend{
    __tag = 'Object.Model.Test';
	__name = 'Test';
	__desc = 'Basic user definition.';
--	__indexfd = {name = "string" , score = "number"};
	__fields = {
		['name'] = { indexType="string", required=true },
		['score'] = { indexType="number", required=true },
	};

    init = function (self,t)
        if not t then return self end;

        self.name = t.name;
        self.score = t.score;
        self.created_time = os.time();

        return self
    end

}

bamboo.registerModel(Test)
function testMain()
    Test:all():del();
    db:del("Test:score:__hash");
    db:del("Test:name:__hash");
    db:del("Test:name:xxxx1:__set");
    db:del("Test:name:xxxx:__set");
    db:del("Test:name:xxxx2:__set");
    db:del("Test:__index");
    db:del("Test:__counter");

    local test1 = Test({name = "xxxx",score = 1.0})
    local test2 = Test({name = "xxxx",score = 1.1})
    local test3 = Test({name = "xxxx",score = 1.2})
    local test4 = Test({name = "xxxx1",score = 2.0})
    local test5 = Test({name = "xxxx1",score = 2.1})
    local test6 = Test({name = "xxxx2",score = 3.0})
    local test7 = Test({name = "xxxx3",score = 2.0})
    
    print("TEST INDEX");
    test1:save(); print("test1",test1.id,test1.name,test1.score);
    assert(tonumber(db:hget("Test:name:__hash",test1.name)) == tonumber(test1.id), "the hash vaule must be the id"); 
    assert(tonumber(db:zscore("Test:score:__hash",test1.id)) == tonumber(test1.score), "the score vaule must be the id"); 

    test2:save(); print("test2",test2.id,test2.name,test2.score);
    assert((db:hget("Test:name:__hash",test1.name)) == "Test:name:xxxx:__set", 
                    "the hash vaule must be the key of the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__set",test1.id) , 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__set",test2.id) , 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:scard("Test:name:xxxx:__set")==2 , 
                    "the members number in the Set now must be 2"); 
    assert(tonumber(db:zscore("Test:score:__hash",test1.id)) == tonumber(test1.score), 
                    "the score vaule must be the id"); 
    assert(tonumber(db:zscore("Test:score:__hash",test2.id)) == tonumber(test2.score), 
                    "the score vaule must be the id"); 

    test3:save(); print("test3",test3.id,test3.name,test3.score);
    assert((db:hget("Test:name:__hash",test1.name)) == "Test:name:xxxx:__set", 
                    "the hash vaule must be the key of the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__set",test1.id), 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__set",test2.id) , 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__set",test3.id) , 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:scard("Test:name:xxxx:__set")==3 , 
                    "the members number in the Set now must be 3"); 
    assert(tonumber(db:zscore("Test:score:__hash",test2.id)) == tonumber(test2.score), 
                    "the score vaule must be the id"); 

    test4:save(); print("test4",test4.id,test4.name,test4.score);
    test5:save(); print("test5",test5.id,test5.name,test5.score);
    test6:save(); print("test6",test6.id,test6.name,test6.score);
    test7:save(); print("test7",test7.id,test7.name,test7.score);
   
--  print("------------------------");
--    local ids = Test:filter({"or", name="xxxx", score = lt(2.0)})
--    print("+++++++++++++");
--    ptable(ids);
  
    --test number eq
    local ids = Test:filter({score = eq(1.1)})
    assert(#ids == 1, "test number eq failed");
    assert(tonumber(ids[1]) == 2, "test number eq failed");
    local ids = Test:filter({score = eq(2.0)})
    assert(#ids == 2, "test number eq failed");
    assert(tonumber(ids[1]) == 4 or tonumber(ids[1]) == 7, "test number eq failed");
    assert(tonumber(ids[2]) == 4 or tonumber(ids[2]) == 7, "test number eq failed");
    local ids = Test:filter({score = eq(210.0)})
    assert(#ids == 0, "test number eq failed");
    print("number eq PASSED");


    --test number uneq
    local ids = Test:filter({score = uneq(1.1)})
    assert(#ids == 6, "test number uneq failed");
    local ids = Set(ids);
    assert(ids['2']==nil, "test number uneq failed");
    local ids = Test:filter({score = uneq(2.0)})
    assert(#ids == 5, "test number uneq failed");
    local ids = Set(ids);
    assert(ids['4'] ==nil, "test number uneq failed");
    assert(ids['7'] ==nil, "test number uneq failed");
    local ids = Test:filter({score = uneq(210.0)})
    assert(#ids == 7, "test number uneq failed");
    print("number uneq PASSED");

    --test number lt
    local ids = Test:filter({score = lt(1.1)})
    assert(#ids == 1, "test number lt failed");
    local ids = Set(ids);
    assert(ids['1'], "test number lt failed");
    local ids = Test:filter({score = lt(2.0)})
    assert(#ids == 3, "test number lt failed");
    local ids = Set(ids);
    assert(ids['1'], "test number lt failed");
    assert(ids['2'], "test number lt failed");
    assert(ids['3'], "test number lt failed");
    local ids = Test:filter({score = lt(3)})
    assert(#ids == 6, "test number lt failed");
    assert(ids['6']==nil, "test number lt failed");
    print("number lt PASSED");


    --test number gt
    local ids = Test:filter({score = gt(1.1)})
    assert(#ids == 1, "test number gt failed");
    local ids = Set(ids);
    assert(ids['1'], "test number gt failed");
    local ids = Test:filter({score = gt(2.0)})
    assert(#ids == 3, "test number gt failed");
    local ids = Set(ids);
    assert(ids['1'], "test number gt failed");
    assert(ids['2'], "test number gt failed");
    assert(ids['3'], "test number gt failed");
    local ids = Test:filter({score = gt(3)})
    assert(#ids == 6, "test number gt failed");
    assert(ids['6']==nil, "test number gt failed");
    print("number gt PASSED");
end



testMain()













