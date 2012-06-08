#!/usr/bin/env lua  
redis = require 'hiredis'
list = require 'bamboo.script.list'
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
local key = "list1";
local tbl = {"val10","val11","val12"}

--clear 
local str = "";
str = str .. list.del();
str = str .. [[
    return ldel(ARGV[1]);
    ]]
rac = db:command("eval",str,0,key);


--append and retrieve
str = "";
str = str .. list.append() ..list.retrieve();--载入脚本函数
str = str .. [[
        lappend(ARGV[1], ARGV[2]);
        lappend(ARGV[1], ARGV[3]);
        return lretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"list1","list2");
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "list"..i,"list value fault");
    n = n +1;
end
assert(n == 2 ,"return lenth must equal len" .. n);
print("LIST PUSH AND RETRIEVE PASS");


--prepend
str = "";
str = str .. list.prepend() ..list.retrieve()..list.del();--载入脚本函数
str = str .. [[
        ldel(ARGV[1]);
        lprepend(ARGV[1], ARGV[2]);
        lprepend(ARGV[1], ARGV[3]);
        return lretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"list2","list1");
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "list"..i,"list value fault");
    n = n +1;
end
assert(n == 2 ,"return lenth must equal len" .. n);
print("LIST PREPEND PASS");




--save
str = "";
str = str .. list.save() ..list.retrieve()..list.del();--载入脚本函数
str = str .. [[
        ldel(ARGV[1]);
        lsave(ARGV[1], ARGV[2]);
        return lretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,serialize({"list1","list2"}));
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "list"..i,"list value fault");
    n = n +1;
end
assert(n == 2 ,"return lenth must equal len" .. n);
print("LIST SAVE PASS");



--update
str = "";
str = str .. list.update() ..list.retrieve()..list.del();--载入脚本函数
str = str .. [[
        lupdate(ARGV[1], ARGV[2]);
        return lretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,serialize({"list1","list2","list3"}));
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "list"..i,"list value fault");
    n = n +1;
end
assert(n == 3 ,"return lenth must equal len" .. n);
local rac = eval.eval(db,str,key,serialize({"list5"}));
assert(type(rac) == 'table',"return must be table");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "list5","list value fault");
    n = n +1;
end
assert(n == 1 ,"return lenth must equal len" .. n);
print("LIST UPDATE PASS");





--pop
str = "";
str = str .. list.pop() ..list.retrieve()..list.del();--载入脚本函数
str = str .. [[
        return lpop(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key);
assert(type(rac) == 'string',"return must be table");
assert(rac == "list5" ,"return lenth must equal len" .. n);
str = list.retrieve();--载入脚本函数
str = str..[[
        return lretrieve(ARGV[1]);
    ]] --应用逻辑
local rac = eval.eval(db,str,key);
local n = 0;
for i,v in pairs(rac) do 
    n = n +1;
end
assert(n == 0 ,"return must be empty table");
--执行eval
print("LIST POP PASS");





--remove
str = "";
str = str .. list.prepend() ..list.remove()..list.del()..list.retrieve();--载入脚本函数
str = str .. [[
        ldel(ARGV[1]);
        lprepend(ARGV[1], ARGV[2]);
        lprepend(ARGV[1], ARGV[3]);
        lremove(ARGV[1],ARGV[2]);
        return lretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"list2","list1");
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "list1","list value fault");
    n = n +1;
end
assert(n == 1 ,"return lenth must equal len");
print("LIST REMOVE PASS");





--removeByIndex
str = "";
str = str .. list.append() ..list.removeByIndex()..list.del()..list.retrieve();--载入脚本函数
str = str .. [[
        ldel(ARGV[1]);
        lappend(ARGV[1], ARGV[2]);
        lappend(ARGV[1], ARGV[3]);
        lremoveByIndex(ARGV[1],ARGV[4]);
        return lretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"list2","list1",1);
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "list2",v);
    n = n +1;
end
assert(n == 1 ,"return lenth must equal len");
print("LIST REMOVEBYINDEX PASS");


--len 
str = "";
str = str .. list.len() ..list.append()..list.del();--载入脚本函数
str = str .. [[
        ldel(ARGV[1]);
        lappend(ARGV[1], ARGV[2]);
        lappend(ARGV[1], ARGV[3]);
        return llen(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"list1","list2");
assert(type(rac) == 'number',"return must be table");
assert(2 == rac ,"return lenth must equal len" );
print("LIST LEN PASS");




--del
str = "";
str = str .. list.prepend() ..list.remove()..list.del()..list.retrieve();--载入脚本函数
str = str .. [[
        ldel(ARGV[1]);
        return lretrieve(ARGV[1]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key);
local n = 0;
for i,v in pairs(rac) do 
    assert(v == "list1","list value fault");
    n = n +1;
end
assert(n == 0 ,"return lenth must equal len");
print("LIST DEL PASS");


--has 
str = "";
str = str ..list.del().. list.len() ..list.append()..list.has();--载入脚本函数
str = str .. [[
        ldel(ARGV[1]);
        lappend(ARGV[1], ARGV[2]);
        lappend(ARGV[1], ARGV[3]);
        return lhas(ARGV[1],ARGV[4]);
    ]] --应用逻辑

--执行eval
local rac = eval.eval(db,str,key,"list1","list2","list2");
assert(type(rac) == 'string',"return must be table");
assert('true' == rac ,"return lenth must equal len" );
local rac = eval.eval(db,str,key,"list1","list2","list20");
assert(type(rac) == 'string',"return must be table");
assert('false' == rac ,"return lenth must equal len" );
print("LIST LEN PASS");











