#!/usr/bin/env lua  
redis = require 'hiredis'
zfifo = require 'bamboo.script.zfifo'
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

function dump(key)
local str = "";
str = str .. zfifo.push() ..zfifo.retrieveWithScores();--载入脚本函数
str = str .. [[
        return zfretrieveWithScores(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key);
assert(type(rac) == 'table',"return must be table");
for i=1,#rac,2 do 
    print(rac[i],rac[i+1]);
end
print("")
end


--测试数据
local key = "zfifo:";
local key1 = "zfifo1:";
local len = 5;

--clear 
local str = "";
str = str .. zfifo.del();
str = str .. [[
    zfdel(ARGV[1]);
    return zfdel(ARGV[2]);
    ]]
rac = db:command("eval",str,0,key,key1);

--push and retrieve
str = "";
str = str .. zfifo.push() ..zfifo.retrieve();--载入脚本函数
str = str .. [[
        zfpush(ARGV[1], ARGV[2], ARGV[9]);
        zfpush(ARGV[1], ARGV[3], ARGV[9]);
        zfpush(ARGV[1], ARGV[4], ARGV[9]);
        zfpush(ARGV[1], ARGV[5], ARGV[9]);
        zfpush(ARGV[1], ARGV[6], ARGV[9]);
        zfpush(ARGV[1], ARGV[7], ARGV[9]);
        zfpush(ARGV[1], ARGV[8], ARGV[9]);
        return zfretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"zfifo7","zfifo6","zfifo5","zfifo4",
                        "zfifo3","zfifo2","zfifo1",len);
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "zfifo"..i,v);
    n = n +1;
end
assert(n == len ,"return lenth must equal len");
print("zfifo PUSH AND RETRIEVE PASS");


--pop
str = zfifo.pop();
str = str .. [[
    return zfpop(ARGV[1]);
    ]]

local rac = eval.eval(db,str,key);
assert(type(rac) == 'string',type(rac));
str = zfifo.retrieve();--载入脚本函数
str = str .. [[
        return zfretrieve(ARGV[1]);
        ]]
local rac = eval.eval(db,str,key);
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "zfifo"..i,"zfifo value fault");
    n = n +1;
end
assert(n == len-1 ,"return lenth must equal len");
print("zfifo POP PASS");




--remove
str = zfifo.remove();
str = str .. [[
    return zfremove(ARGV[1],ARGV[2]);
    ]]
local rac = eval.eval(db,str,key,"zfifo4");
assert(type(rac) == 'number',"return must be number");
assert(rac == 1,"return must be 1");
str = zfifo.remove();
str = str .. [[
    return zfremove(ARGV[1],ARGV[2]);
    ]]
local rac = eval.eval(db,str,key,"zfifo5");
assert(type(rac) == 'number',"return must be number");
assert(rac == 0,"return must be 0");
str = zfifo.retrieve();--载入脚本函数
str = str .. [[
        return zfretrieve(ARGV[1]);
        ]]
local rac = eval.eval(db,str,key);
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "zfifo"..i,"zfifo value fault");
    n = n +1;
end
assert(n == len-2 ,"return lenth must equal len");
print("zfifo REMOVE PASS");


--len 
str = zfifo.num();
str = str .. [[
    return zfnum(ARGV[1]);
    ]]
local rac = eval.eval(db,str,key);
assert(type(rac) == 'number',"return must be number");
assert(rac == 3,"return must be 3");
print("zfifo NUM  PASS");

--has 
str = zfifo.has();
str = str .. [[
    return zfhas(ARGV[1],ARGV[2]);
    ]]
local rac = eval.eval(db,str,key,"zfifo2");
assert(rac == 'true',"return must be true");
local rac = db:command("eval",str,0,key,"zfifo20");
assert(rac == 'false' ,"return must be false");
print("zfifo HAS   PASS");



--removeByScore
str = zfifo.removeByScore()..zfifo.del()..zfifo.push();
str = str .. [[
    zfdel(ARGV[1]);
    zfpush(ARGV[1], ARGV[2], ARGV[9]);
    zfpush(ARGV[1], ARGV[3], ARGV[9]);
    zfpush(ARGV[1], ARGV[4], ARGV[9]);
    zfpush(ARGV[1], ARGV[5], ARGV[9]);
    zfpush(ARGV[1], ARGV[6], ARGV[9]);
    zfpush(ARGV[1], ARGV[7], ARGV[9]);
    zfpush(ARGV[1], ARGV[8], ARGV[9]);
    return zfremoveByScore(ARGV[1],ARGV[10]);
    ]]
local rac = eval.eval(db,str,key,"zfifo7","zfifo6","zfifo5","zfifo4",
                        "zfifo3","zfifo2","zfifo1",len,5);
assert(type(rac) == 'number',"return must be number");
assert(rac == 1,"return must be 1");
str = zfifo.removeByScore();
str = str .. [[
    return zfremoveByScore(ARGV[1],ARGV[2]);
    ]]
local rac = eval.eval(db,str,key,100);
assert(type(rac) == 'number',"return must be number");
assert(rac == 0,"return must be 0");
print("zfifo REMOVEBYSCORE PASS");



