#!/usr/bin/env lua  
redis = require 'hiredis'
string = require 'bamboo.script.string'
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
local key = "string1";

--clear 
local str = "";
str = str .. string.del();
str = str .. [[
    return strdel(ARGV[1]);
    ]]
rac = db:command("eval",str,0,key);


--add and retrieve
str = "";
str = str .. string.add() ..string.retrieve();--载入脚本函数
str = str .. [[
        stradd(ARGV[1], ARGV[2]);
        stradd(ARGV[1], ARGV[3]);
        return strretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"string1","string2");
assert(type(rac) == 'string',type(rac));
assert(rac == "string2" ,rac);
print("string ADD AND RETRIEVE PASS");


--save
str = "";
str = str .. string.save() ..string.retrieve()..string.del();--载入脚本函数
str = str .. [[
        strdel(ARGV[1]);
        strsave(ARGV[1], ARGV[2]);
        return strretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"string3");
assert(type(rac) == 'string',type(rac));
assert(rac == "string3" ,rac);
print("string SAVE PASS");



--update
str = "";
str = str .. string.update() ..string.retrieve()..string.del();--载入脚本函数
str = str .. [[
        strdel(ARGV[1]);
        strupdate(ARGV[1], ARGV[2]);
        return strretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"string4");
assert(type(rac) == 'string',type(rac));
assert(rac == "string4" ,rac);
print("string UPDATE PASS");


--remove
str = "";
str = str ..string.add() .. string.remove()..string.del()..string.retrieve();--载入脚本函数
str = str .. [[
        strdel(ARGV[1]);
        stradd(ARGV[1], ARGV[2]);
        strremove(ARGV[1]);
        return strretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"string4");
assert(type(rac) == 'string',type(rac));
assert(rac == "" ,rac);
print("string REMOVE PASS");



--num 
str = "";
str = str .. string.num() ..string.add()..string.del();--载入脚本函数
str = str .. [[
        return strnum(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key);
assert(type(rac) == 'number',type(rac));
assert(1 == rac ,"return lenth must equal len" );
print("string NUM PASS");


--del
str = "";
str = str .. string.add() ..string.retrieve()..string.del();--载入脚本函数
str = str .. [[
        stradd(ARGV[1],ARGV[2]);
        strdel(ARGV[1]);
        return strretrieve(ARGV[1]);
    ]] --应用逻辑
--执行eval
local rac = eval.eval(db,str,key);
assert(rac['name'] == 'NIL',rac['name']);
print("string DEL PASS");


--has 
str = "";
str = str ..string.del().. string.add()..string.has();--载入脚本函数
str = str .. [[
        strdel(ARGV[1]);
        stradd(ARGV[1], ARGV[2]);
        return strhas(ARGV[1],ARGV[3]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"string1","string1");
assert(rac == 'true',rac);
local rac = eval.eval(db,str,key,"string1","string2");
assert(rac == 'false',rac);
print("string HAS PASS");











