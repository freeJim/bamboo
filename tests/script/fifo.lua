#!/usr/bin/env lua  
redis = require 'hiredis'
fifo = require 'bamboo.script.fifo'
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
local key = "FIFO:";
local key1 = "FIFO1:";
local len = 5;

--clear 
local str = "";
str = str .. fifo.del();
str = str .. [[
    fdel(ARGV[1]);
    return fdel(ARGV[2]);
    ]]
rac = db:command("eval",str,0,key,key1);


--push and retrieve
str = "";
str = str .. fifo.push() ..fifo.retrieve();--载入脚本函数
str = str .. [[
        fpush(ARGV[1], ARGV[2], ARGV[9]);
        fpush(ARGV[1], ARGV[3], ARGV[9]);
        fpush(ARGV[1], ARGV[4], ARGV[9]);
        fpush(ARGV[1], ARGV[5], ARGV[9]);
        fpush(ARGV[1], ARGV[6], ARGV[9]);
        fpush(ARGV[1], ARGV[7], ARGV[9]);
        fpush(ARGV[1], ARGV[8], ARGV[9]);
        return fretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
--local rac = db:command("eval",str,0,key,"fifo1","fifo2","fifo3","fifo4","fifo5","fifo6","fifo7",5);
local rac = eval.eval(db,str,key,"fifo7","fifo6","fifo5","fifo4","fifo3","fifo2","fifo1",len);
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in ipairs(rac) do 
    assert(v == "fifo"..i,"fifo value fault");
    n = n +1;
end
assert(n == len ,"return lenth must equal len");
print("FIFO PUSH AND RETRIEVE PASS");



--pop
str = fifo.pop();
str = str .. [[
    return fpop(ARGV[1]);
    ]]

local rac = eval.eval(db,str,key);
assert(type(rac) == 'string',"return must be string");
assert(rac == 'fifo5',"return must be string");
str = fifo.retrieve();--载入脚本函数
str = str .. [[
        return fretrieve(ARGV[1]);
        ]]
local rac = eval.eval(db,str,key);
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in ipairs(rac) do 
    assert(v == "fifo"..i,"fifo value fault");
    n = n +1;
end
assert(n == len-1 ,"return lenth must equal len");
print("FIFO POP PASS");



--remove
str = fifo.remove();
str = str .. [[
    return fremove(ARGV[1],ARGV[2]);
    ]]
local rac = eval.eval(db,str,key,"fifo4");
assert(type(rac) == 'number',"return must be number");
assert(rac == 1,"return must be 1");
str = fifo.remove();
str = str .. [[
    return fremove(ARGV[1],ARGV[2]);
    ]]
local rac = eval.eval(db,str,key,"fifo5");
assert(type(rac) == 'number',"return must be number");
assert(rac == 0,"return must be 0");
str = fifo.retrieve();--载入脚本函数
str = str .. [[
        return fretrieve(ARGV[1]);
        ]]
local rac = eval.eval(db,str,key);
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in ipairs(rac) do 
    assert(v == "fifo"..i,"fifo value fault");
    n = n +1;
end
assert(n == len-2 ,"return lenth must equal len");
print("FIFO REMOVE PASS");


--len 
str = fifo.len();
str = str .. [[
    return flen(ARGV[1]);
    ]]
local rac = eval.eval(db,str,key);
assert(type(rac) == 'number',"return must be number");
assert(rac == 3,"return must be 3");
print("FIFO LEN  PASS");

--has 
str = fifo.has();
str = str .. [[
    return fhas(ARGV[1],ARGV[2]);
    ]]
local rac = eval.eval(db,str,key,"fifo2");
assert(rac == 'true',"return must be true");
local rac = db:command("eval",str,0,key,"fifo20");
assert(rac == 'false' ,"return must be false");
print("FIFO HAS   PASS");






