#!/usr/bin/env lua  
redis = require 'hiredis'
hash = require 'bamboo.script.hash'
eval = require 'bamboo.script.eval'
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
assert(db:command("select",WHICH_DB));



--测试数据
local ac = {id = '10', method="get"}
local ac1 = {id = '20', method="get"}
local ac2 = {id = '21', method="getS"}
local key = "Acess:" .. ac.id ;
local key1 = "Acess:" .. ac1.id ;
local key2 = "Acess:" .. ac2.id ;

--add  and retrieve
local str = "";
str = str .. hash.add();--载入脚本函数
str = str .. [[
        hadd(ARGV[1],ARGV[2]);
        hadd(ARGV[3],ARGV[4]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,serialize(ac),key1,serialize(ac1),key,key1);
assert(type(rac) =='table', rac);
str = hash.retrieve();
str = str .. [[
    return hretrieve(ARGV[1]);
    ]];
rac = eval.eval(db,str,key);
assert(type(rac) == 'table',"hash add or retrieve  failed");
assert(#rac == 4,"hash add or retrieve failed");
for i=1,2 do 
    assert(tostring(ac[rac[2*(i-1)+1]]) == rac[2*i], "hash add or retrieve faild");
end
print("HASH ADD TEST PASS");
print("HASH RETRIEVE TEST PASS");



--update
str = hash.update() .. hash.retrieve();
str = str .. [[
    hupdate(ARGV[1],ARGV[2]);
    return hretrieve(ARGV[1]);
    ]];
rac = eval.eval(db,str,key,serialize(ac2));
assert(type(rac) == 'table',"hash update failed");
assert(#rac == 4,"hash update  failed");
for i=1,2 do 
    assert(tostring(ac2[rac[2*(i-1)+1]]) == rac[2*i], "update faild");
end
print("HASH UPDATE TEST PASS");



--save
str = hash.save() .. hash.retrieve();
str = str .. [[
    hsave(ARGV[1],ARGV[2]);
    return hretrieve(ARGV[1]);
    ]];
rac = eval.eval(db,str,key2,serialize(ac2));
assert(type(rac) == 'table',"hash save failed");
assert(#rac == 4,"hash save failed");
for i=1,2 do 
    assert(tostring(ac2[rac[2*(i-1)+1]]) == rac[2*i], "save faild");
end
print("HASH SAVE TEST PASS");




--num
str = hash.num() ;
str = str .. [[
    return hnum(ARGV[1]);
    ]];
rac = eval.eval(db,str,key2);
local ac2num = 0;
for k,v in pairs(ac2) do 
    ac2num = ac2num + 1;
end
assert(tonumber(rac) == ac2num,"hash num failed");
print("HASH NUM TEST PASS");


--has
str = hash.has() ;
str = str .. [[
    return hhas(ARGV[1],ARGV[2]);
    ]];
rac = eval.eval(db,str,key2,'method');
assert(rac=='true',"hash has failed");
rac = eval.eval(db,str,key2,'method1');
assert(rac=='false',"hash has failed");
print("HASH HAS TEST PASS");


--remove 
str = hash.remove()..hash.has() ;
str = str .. [[
    return hremove(ARGV[1],ARGV[2]);
    ]];
rac = eval.eval(db,str,key2,'method');
assert(rac == 1,"hash remove failed");
str = hash.has() ;
str = str .. [[
    return hhas(ARGV[1],ARGV[2]);
    ]];
rac = eval.eval(db,str,key2,'method');
assert(rac == 'false',"hash remove failed");
str = hash.has() ;
str = str .. [[
    return hhas(ARGV[1],ARGV[2]);
    ]];
rac = eval.eval(db,str,key2,'id');
assert(rac == 'true',"hash remove failed");
print("HASH REMOVE TEST PASS");





















