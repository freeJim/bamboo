module(..., package.seeall)
local tinsert, tremove = table.insert, table.remove
local format = string.format
local db = BAMBOO_DB

------------------------public ------------
local function getClassName(self)
	if type(self) ~= 'table' then return nil end
	return self.__tag:match('%.(%w+)$')
end

-- return the key of some string like 'User:__index'
--
local function getIndexKey(self)
	return getClassName(self) + ':__index'
end

function getFieldIndexKey(self, field)
	return getClassName(self) .. ":" .. field.. ':__index'
end


function getSetIndexKey(self, field, value)
	return getClassName(self) .. ":" .. field..":".. value .. ':__index'
end


---------------------------make index ------------
--remove the string index of the field of the object
function indexFieldStrRemove(self, field)
    local indexKey = getFieldIndexKey(self,field);
    local id = db:hget(indexKey, self[field]); 
    if id==nil then 
        --do nothing
    elseif tonumber(id) then--this field only has a id
        if tonumber(id) == tonumber(self.id) then 
            db:hdel(indexKey, self[field]);
        end
    else --this field has a id set 
        local indexSetKey = id;
        db:srem(indexSetKey, self.id);

        local num = db:scard(indexSetKey) ;
        if num == 1 then 
            local ids = db:smembers(indexSetKey);
            db:del(indexSetKey);
            db:hset(indexKey,self[field],ids[1]);
        end
    end
end

--create the string index of the field of the object
function indexFieldStr(self,field) --add the new
    local indexKey = getFieldIndexKey(self,field);
    local id = db:hget(indexKey, self[field]); 
    if id==nil then 
        db:hset(indexKey, self[field], self.id);
    elseif tonumber(id) then--this field already has a id
        local indexSetKey = getSetIndexKey(self, field, self[field]);
        db:sadd(indexSetKey, id);
        db:sadd(indexSetKey, self.id);
        db:hset(indexKey, self[field], indexSetKey);
    else -- this field has a id set, the id is the set name  
        db:sadd(id, self.id);
    end
end

-- create or update the index of the object field
function indexField(self, field, indexType, oldObj)
    local value = self[field];
    if oldObj and oldObj[field] == value then
        return;
    end
    
    if indexType == 'number' then
        local indexKey = getFieldIndexKey(self,field);
        db:zadd(indexKey, value, self.id);
    elseif indexType == 'string' then
        if oldObj then
            indexFieldStrRemove(oldObj,field);--remove the old
        end
        indexFieldStr(self,field); --add the new
    else                
    end
end

-- create or update the index of the object  or the object field
-- if create, must be called after save() and the newIndex must be true
-- if update, must be called before save() and the newIndex must be false
-- NOTE: the application developer should not call this function, becuase 
--       it autolly be called in the Model:save(), Model:del(), and so on.      
function index(self,newIndex,field)
	I_AM_INSTANCE(self)
    if field then 
	    checkType(field, 'string')
    end

    -- start index
    if newIndex then 
        if field then -- index for field 
            indexType = self.__fields[field].indexType;
            if indexType then 
                indexField(self, field, indexType, nil)
            end
        else -- index for object
            for field, def in pairs(self.__fields) do
                if def.indexType then
                    indexField(self, field, def.indexType, nil);
                end
            end
        end
    else
        local oldObj = self:getClass():getById(self.id);

        if field then -- index for field 
            indexType = self.__fields[field].indexType;
            if indexType then 
                indexField(self, field, nil, oldObj)
            end
        else -- index for object
            for field, def in pairs(self.__fields) do
                if def.indexType then
                    indexField(self, field, def.indexType, oldObj);
                end
            end
        end
    end
end;

---------------- use index ---------------------------
--[[function filterQueryArgs(self,query_args)
	if query_args and query_args['id'] then
		-- remove 'id' query argument
		print("[Warning] Filter doesn't support search by id.")
		query_args['id'] = nil 
	end


    local logic = 'and'
	-- normalize the 'and' and 'or' logic
	if query_args[1] then
		assert(query_args[1] == 'or' or query_args[1] == 'and', 
			"[Error] The logic should be 'and' or 'or', rather than: " .. tostring(query_args[1]))
		if query_args[1] == 'or' then
			logic = 'or'
		end
		query_args[1] = nil
	end

    return logic, query_args;
end

-- walkcheck can process full object and partial object
function walkcheck(self,objs,query_args,logic_choice)
	local query_set = QuerySet()

	for i = 1, #objs do
		local obj = objs[i]
		--DEBUG(obj)
		-- check the object's legalery, only act on valid object
		--if isValidInstance(obj) then
		local flag = checkLogicRelation(self, obj, query_args, logic_choice)
		
		-- if walk to this line, means find one 
		if flag then
			tinsert(query_set, obj)
		end
		--end
	end

    return query_set;
end

function filterQuerySet(self, query_args, start, stop, is_rev, is_get)
	-- if query table is empty, return slice instances
	if isFalse(query_args) then 
		local start = start or 1
		local stop = stop or -1
		local nums = self:numbers()
		return self:slice(start, stop, is_rev);
	end


	local all_ids = self
	-- nothing in id list, return empty table
	if #all_ids == 0 then return List() end

	-- create a query set
	local query_set = nil; 
	local logic_choice = (logic == 'and')
	local partially_got = false

    query_set = walkcheck(objs);
	
	-- here, _t_query_set is the all instance fit to query_args now
	local _t_query_set = query_set
	if #query_set == 0 then return query_set end
	
	if is_get == 'get' then
		query_set = (is_rev == 'rev') and List {_t_query_set[#_t_query_set]} or List {_t_query_set[1]}
	else	
		-- now id_list is a list containing all id of instances fit to this query_args rule, so need to slice
		query_set = _t_query_set:slice(start, stop, is_rev)
	end

	return query_set
end
--]]
function filterEqString(self, field, value)
    local indexKey = getFieldIndexKey(self,field);
    local id = db:hget(indexKey, value); 
    if id == nil then 
        return List();
    elseif tonumber(id) then
        return {id};
    else
        local ids = db:smembers(id);
        return ids;
    end
end

function filterBtNumber(self,field,min,max)
    local indexKey = getFieldIndexKey(self,field);
    return db:zrangebyscore(indexKey,min,max)
end

function filterNumber(self,field,name,args)
    local all_ids = {};

    if name == 'eq' then-- equal 
        all_ids = filterBtNumber(self,field,args,args);
    elseif name == 'uneq' then --unequal
        local lefts = filterBtNumber(self,field,-math.huge,"("..tostring(args));
        local rights = filterBtNumber(self,field,"("..tostring(args),math.huge);
        all_ids = lefts;
        for i,v in ipairs(rights) do 
            table.insert(all_ids,v);
        end
    elseif name == 'lt' then -- less then
        all_ids = filterBtNumber(self,field,-math.huge,"("..args);
    elseif name == 'gt' then -- great then
        all_ids = filterBtNumber(self,field,"("..args,math.huge);
    elseif name == 'le' then -- less and equal then
        all_ids = filterBtNumber(self,field,-math.huge,args);
    elseif name == 'ge' then -- great and equal then
        all_ids = filterBtNumber(self,field,args,math.huge);
    elseif name == 'bt' then   
        all_ids = filterBtNumber(self,field,"("..args[1],"("..args[2]);
    elseif name == 'be' then
        all_ids = filterBtNumber(self,field,args[1],args[2]);
    elseif name == 'outside' then
        all_ids = filterBtNumber(self,field,-math.huge,"("..args[1]);
        local t = filterBtNumber(self,field,"("..args[2], math.huge);
        for i,v in ipairs(t) do 
            table.insert(all_ids,v);
        end         
    elseif name == 'inset' then
        for i,v in ipairs(args) do
            local ids = filterBtNumber(self,field,v,v);
            for __,id in ipairs(ids) do 
                table.insert(all_ids, id);
            end
	end
    elseif name == 'uninset' then
        print("[Warning]  uneq string not surpport");
        all_ids = {};
    else
    end

    return all_ids;
end

function filterString(self,field,name,args)
    local all_ads = {};

    if name == 'eq' then-- equal 
        all_ids = filterEqString(self,field,args);
    elseif name == 'uneq' then --unequal
        print("[Warning]  uneq string not surpport");
        all_ids = {};
    elseif name == 'lt' then -- less then
        print("[Warning]  lt string not surpport");
        all_ids = {};
    elseif name == 'gt' then -- great then
        print("[Warning]  gt string not surpport");
        all_ids = {};
    elseif name == 'le' then -- less and equal then
        print("[Warning]  le string not surpport");
        all_ids = {};
    elseif name == 'ge' then -- great and equal then
        print("[Warning]  ge string not surpport");
        all_ids = {};
    elseif name == 'bt' then  -- between 
        print("[Warning]  bt string not surpport");
        all_ids = {};
    elseif name == 'be' then  -- between and equal
        print("[Warning]  be string not surpport");
        all_ids = {};
    elseif name == 'outside' then
        print("[Warning]  outside string not surpport");
        all_ids = {};
    elseif name == 'contains' then
        print("[Warning]  contains string not surpport");
        all_ids = {};
    elseif name == 'uncontains' then
        print("[Warning]  uncontains string not surpport");
        all_ids = {};
    elseif name == 'startsWith' then
        print("[Warning]  startsWith string not surpport");
        all_ids = {};
    elseif name == 'unstartsWith' then
        print("[Warning] unstartsWith string not surpport");
        all_ids = {};
    elseif name == 'endsWith' then
        print("[Warning] endsWith string not surpport");
        all_ids = {};
    elseif name == 'unendsWith' then
        print("[Warning] unendsWith string not surpport");
        all_ids = {};
    elseif name == 'inset' then
        all_ids = {};
        for i,v in ipairs(args) do 
            local t = filterEqString(self,field,v);
            for _,id in ipairs(t) do 
                table.insert(all_ids,id);
            end
        end
    elseif name == 'uninset' then
        print("[Warning]  outside string not surpport");
        all_ids = {};
    end

    return all_ids;
end

function filterLogic( logic, all_ids)
    if logic ==  "and" then
        local ids = {};

        local tset = {};
        for i=2, #all_ids do 
            tset[i-1] = Set(all_ids[i]);
        end

        for i,v in ipairs(all_ids[1]) do 
            local flag = true;
            for __,set in ipairs(tset) do
                if set[v] == nil then
                    flag = false;
                    break;
                end
            end

            if flag then 
                table.insert(ids,v);
            end
        end

        return ids;
    elseif logic == 'or' then
        local t = Set(all_ids[1]);
        for i=2,#all_ids do 
            for __,v in ipairs(all_ids[i]) do 
                t[v] = true;
            end
        end

        local ids = {};
        for k,v in pairs(t) do 
            table.insert(ids,k);
        end
        
        return ids;
    else
        print("[Warning]  unknown logic :" .. logic);
        return {};
    end
end
--- fitler some instances belong to this model
-- @param query_args: query arguments in a table
function filter(self, query_args, logic)
	--[[I_AM_CLASS_OR_QUERY_SET(self)
	assert(type(query_args) == 'table' or type(query_args) == 'function', 
        '[Error] the query_args passed to filter must be table or function.')
	if start then assert(type(start) == 'number', '[Error] @filter - start must be number.') end
	if stop then assert(type(stop) == 'number', '[Error] @filter - stop must be number.') end
	if is_rev then assert(type(is_rev) == 'string', '[Error] @filter - is_rev must be string.') end
--]]
    local is_query_table = (type(query_args) == 'table')

    --[[ deal args
    local query_str_iden
    if is_query_table then
        logic, query_args = filterQueryArgs(self,query_args); 
    end--]]

    local all_ids = {};
    local i = 0;
    if type(query_args) == 'table' then 
        for field,value in pairs(query_args) do 
            i = i + 1;
            if not self.__fields[field] then 
                return List();
            end

            if type(value) == 'function' then 
                local flag,name,args = value();--get the args
                if self.__fields[field].indexType == 'number' then 
                    all_ids[i] = filterNumber(self,field,name,args);
                elseif self.__fields[field].indexType == 'string' then 
                    all_ids[i] = filterString(self,field,name,args);
                else
                    all_ids[i] = {};
                end
            else 
                if self.__fields[field].indexType == 'number' then 
                    all_ids[i] = filterEqNumber(self,field,value);
                elseif self.__fields[field].indexType == 'string' then 
                    all_ids[i] = filterEqString(self,field,value);
                else
                    all_ids[i] = {};
                end
            end
        end
    else
        print("rule index not surport");
    end

    if #all_ids == 1 then 
        return all_ids[1];
    end

    return filterLogic(logic, all_ids);
end;

