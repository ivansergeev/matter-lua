
-- Table

-- Create new table instance with extra methods
-- local t = Table{'a','b','c'}

function Table(t)
	return setmetatable(t, {__index = table})
end

-- Insert value into table
-- Table{'a'}:push('b'):push('c') > {'a','b','c'}
-- t:push('b'):push('c') > {'a','b','c'}

function table:push(val)
	self[#self + 1] = val
	return self
end

-- Return size of the table
-- Table{'a','b','c'}:size() > 3
-- t:size() > 3

function table:size()
	local i = 0
	for _ in pairs(self) do i += 1 end
	return i
end

-- Concat two tables
-- Table{'a','b','c'}:concat({'x','b','x'}) > {'a','b','c','x','b','x'}
-- t:concat({'x','b','x'}) > {'a','b','c','x','b','x'}

function table:concat(b)
	for _, v in pairs(b) do
		self[#self+1] = v
	end
	return self
end

-- Return index by value
-- string or number only
function table:indexof(value)
	local index = {}

	for k, v in pairs(self) do
		index[v]=k
	end

	return index[value]
end

-- Utils

-- Filter table by function
function table.filter(data, func)
	local n = #data
	local result = {}

	for i = 1, n do
		if func(data[i]) then
			table.insert(result, data[i])
		end
	end

	return result
end

-- Union two tables
function table.union(a, b)
	local result = {}
	for k, v in pairs(a) do
		table.insert(result, v)
	end
	for k, v in pairs(b) do
		table.insert(result, v)
	end
	return result
end

-- Quick & Dirty Copy Table
function table.clone(data)
  return {table.unpack(data)}
end

-- Size of table
function table.size(t)
    local i = 0
    for k,_ in pairs(t) do i += 1 end
    return i
end

-- Return index by value

function table.indexof(t, value)
	local index = {}

	for k, v in pairs(t) do
	   index[v]=k
	end

	return index[value]
end

-- Clean table and saving link

function table.clean(t)
	for i=1, #t do
		t[i] = nil
	end
end

function table.deepclone(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[table.deepclone(orig_key)] = table.deepclone(orig_value)
		end
		setmetatable(copy, table.deepclone(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end


function table.deepclone2(obj, seen)
  if type(obj) ~= 'table' then
	  return obj
  end

  if seen and seen[obj] then
	  return seen[obj]
  end

  local s = seen or {}

  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res

  for k, v in pairs(obj) do
	  res[table.deepclone2(k, s)] = table.deepclone2(v, s)
  end

  return res
end


