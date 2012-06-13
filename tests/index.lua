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
    db:del("Test:score:__index");
    db:del("Test:name:__index");
    db:del("Test:name:xxxx1:__index");
    db:del("Test:name:xxxx:__index");
    db:del("Test:name:xxxx2:__index");
    db:del("Test:__index");
    db:del("Test:__counter");

    local test1 = Test({name = "xxxx",score = 1.0})
    local test2 = Test({name = "xxxx",score = 1.1})
    local test3 = Test({name = "xxxx",score = 1.2})
    local test4 = Test({name = "xxxx1",score = 2.0})
    local test5 = Test({name = "xxxx1",score = 2.1})
    local test6 = Test({name = "xxxx2",score = 3.0})
    
    print("TEST INDEX");
    test1:save(); print("test1",test1.id);
    assert(tonumber(db:hget("Test:name:__index",test1.name)) == tonumber(test1.id), "the hash vaule must be the id"); 
    assert(tonumber(db:zscore("Test:score:__index",test1.id)) == tonumber(test1.score), "the score vaule must be the id"); 

    test2:save(); print("test2",test2.id);
    assert((db:hget("Test:name:__index",test1.name)) == "Test:name:xxxx:__index", 
                    "the hash vaule must be the key of the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__index",test1.id) , 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__index",test2.id) , 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:scard("Test:name:xxxx:__index")==2 , 
                    "the members number in the Set now must be 2"); 
    assert(tonumber(db:zscore("Test:score:__index",test1.id)) == tonumber(test1.score), 
                    "the score vaule must be the id"); 
    assert(tonumber(db:zscore("Test:score:__index",test2.id)) == tonumber(test2.score), 
                    "the score vaule must be the id"); 

    test3:save(); print("test3",test3.id);
    assert((db:hget("Test:name:__index",test1.name)) == "Test:name:xxxx:__index", 
                    "the hash vaule must be the key of the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__index",test1.id), 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__index",test2.id) , 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:sismember("Test:name:xxxx:__index",test3.id) , 
                    "the id must be in the Set of objects that the name value be 'xxxx'"); 
    assert(db:scard("Test:name:xxxx:__index")==3 , 
                    "the members number in the Set now must be 3"); 
    assert(tonumber(db:zscore("Test:score:__index",test2.id)) == tonumber(test2.score), 
                    "the score vaule must be the id"); 

    test4:save(); print("test4",test4.id);
    test5:save(); print("test5",test5.id);
    test6:save(); print("test6",test6.id);
   
    test1.name = "xxxx2";
    test1:save();
    test2.name = "xxxx2";
    test2:save();
    test3.name = "xxxx2";
    test3:save();

    print("--------------------------");
    local ids = Test:filter({"and", name="xxxx", score = lt(2.0)})
    print("+++++++++++++");
    ptable(ids);
end



testMain()













