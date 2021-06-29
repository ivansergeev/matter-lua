--[[
* The `Matter.Common` module contains utility functions that are common to all modules.
*
* @class Common
]]--

Common = {}
Common.__index = Common

Common._nextId = 0
Common._seed = 0
Common._nowStartTime = playdate.getSecondsSinceEpoch()


--[[
 * Extends the object in the first argument using the object in the second argument.
 * @method extend
 * @param {} obj
 * @param {boolean} deep
 * @return {} obj extended
 ]]--

 local level = 1

function Common.extend(obj, ...)

	-- print('Common.extend #', level)

	local arguments = {...}
	local n = #arguments

	local argsStart,
		args,
		deepClone

	if (type(arguments[1]) == 'boolean') then
		argsStart = 2
		deepClone = arguments[1]
	else
		argsStart = 1
		deepClone = true
	end

	for i = argsStart, n do

		local source = arguments[i]

		if (source) then
			for prop, val in pairs(source) do

				if (deepClone and val and type(val) == 'table' and not val.__index) then
					if (not obj[prop] or type(obj[prop]) == 'table') then
						obj[prop] = obj[prop] or {}
						level += 1
						Common.extend(obj[prop], deepClone, source[prop])
					else
						obj[prop] = val
					end
				else
					obj[prop] = val
				end
			end
		end
	end

	return obj
end

--[[
 * Creates a new clone of the object, if deep is true references will also be cloned.
 * @method clone
 * @param {} obj
 * @param {bool} deep
 * @return {} obj cloned
 ]]--

function Common.clone(obj, deep)
	return Common.extend({}, deep, obj)
end

--[[
* Returns the list of keys for the given object.
* @method keys
* @param {} obj
* @return {string[]} keys
]]--

function Common.keys(obj)

	if (type(obj) == 'table') then

		local keys = {}

		for key, _ in pairs(obj) do
			table.insert(keys, key)
		end

		return keys
	end

	return {}
end

--[[
* Returns the list of values for the given object.
* @method values
* @param {} obj
* @return {array} Array of the objects property values
]]--
function Common.values(obj)
	local values = {}

	for _, val in pairs(obj) do
		table.insert(values, val)
	end

	return values
end

--[[
* Returns true if the object is a HTMLElement, otherwise false.
* @method isElement
* @param {object} obj
* @return {boolean} True if the object is a HTMLElement, otherwise false
]]--
function Common.isElement(obj)
	return false
end


--[[
* Returns true if the object is an array.
* @method isArray
* @param {object} obj
* @return {boolean} True if the object is an array, otherwise false
]]--
function Common.isArray(obj)
	-- return Object.prototype.toString.call(obj) === '[object Array]';
	return type(obj) == 'table'
end


--[[
	* Returns the given value clamped between a minimum and maximum value.
	* @method clamp
	* @param {number} value
	* @param {number} min
	* @param {number} max
	* @return {number} The value clamped between min and max inclusive
]]--

function Common.clamp(value, min, max)

	if (value < min) then
		return min
	end

	if (value > max) then
		return max
	end

	return value
end


--[[
* Returns the sign of the given value.
* @method sign
* @param {number} value
* @return {number} -1 if negative, +1 if 0 or positive
]]--

function Common.sign(value)
	return value < 0 and -1 or 1
end

--[[
* Returns a random value between a minimum and a maximum value inclusive.
* The function uses a seeded random generator.
* @method random
* @param {number} min
* @param {number} max
* @return {number} A random number between min and max inclusive
]]--

local function _seededRandom()
	-- https://en.wikipedia.org/wiki/Linear_congruential_generator
	Common._seed = (Common._seed * 9301 + 49297) % 233280
	return Common._seed / 233280
end

function Common.random(min, max)
	min = type(min) ~= 'nil' and min or 0
	max = type(max) ~= 'nil' and max or 1
	return min + _seededRandom() * (max - min)
end


--[[
* Shows a `console.warn` message only if the current `Common.logLevel` allows it.
* The message will be prefixed with 'matter-js' to make it easily identifiable.
* @method warn
* @param ...objs {} The objects to log.
]]--

function Common.warn(...)

	local arguments = {...}
	print(table.unpack(arguments))

end
--
--[[
* Returns the next unique sequential ID.
* @method nextId
* @return {Number} Unique sequential ID
]]--

function Common.nextId()

	Common._nextId += 1
	return Common._nextId
end

--[[
* A cross browser compatible indexOf implementation.
* @method indexOf
* @param {array} haystack
* @param {object} needle
* @return {number} The position of needle in haystack, otherwise -1.
]]--

function Common.indexOf(haystack, needle)

	local result = table.indexOfElement(haystack, needle)

	if (result) then
		return result
	end

	local n = table.size(haystack)

	for i=1, n do
		if (haystack[i] == needle) then
			return i
		end
	end

	return nil
end


-- UNUSED
-- --[[
-- * Gets a value from `base` relative to the `path` string.
-- * @method get
-- * @param {} obj The base object
-- * @param {string} path The path relative to `base`, e.g. 'Foo.Bar.baz'
-- * @param {number} [begin] Path slice begin
-- * @param {number} [end] Path slice end
-- * @return {} The object at the given path
-- ]]--
-- Common.get = function(obj, path, begin, end) {
-- 	path = path.split('.').slice(begin, end);
--
-- 	for (var i = 0; i < path.length; i += 1) {
-- 		obj = obj[path[i]];
-- 	}
--
-- 	return obj;
-- };
--
-- --[[
-- * Sets a value on `base` relative to the given `path` string.
-- * @method set
-- * @param {} obj The base object
-- * @param {string} path The path relative to `base`, e.g. 'Foo.Bar.baz'
-- * @param {} val The value to set
-- * @param {number} [begin] Path slice begin
-- * @param {number} [end] Path slice end
-- * @return {} Pass through `val` for chaining
-- ]]--
-- Common.set = function(obj, path, val, begin, end) {
-- 	var parts = path.split('.').slice(begin, end);
-- 	Common.get(obj, path, 0, -1)[parts[parts.length - 1]] = val;
-- 	return val;
-- };
--
-- --[[
-- * Shuffles the given array in-place.
-- * The function uses a seeded random generator.
-- 	* @method shuffle
-- 	* @param {array} array
-- 	* @return {array} array shuffled randomly
-- 	]]--
-- 	Common.shuffle = function(array) {
-- 		for (var i = array.length - 1; i > 0; i--) {
-- 			var j = Math.floor(Common.random() * (i + 1));
-- 			var temp = array[i];
-- 			array[i] = array[j];
-- 			array[j] = temp;
-- 		}
-- 		return array;
-- 	};
--
--[[
* Randomly chooses a value from a list with equal probability.
* The function uses a seeded random generator.
* @method choose
* @param {array} choices
* @return {object} A random choice object from the array
]]--

-- function Common.choose(choices)
-- 	return choices[math.floor(Common.random() * #choices)]
-- end
--
--
-- --[[
-- * Returns true if the object is a function.
-- * @method isFunction
-- * @param {object} obj
-- * @return {boolean} True if the object is a function, otherwise false
-- ]]--
-- Common.isFunction = function(obj) {
-- return typeof obj === "function";
-- };
--
-- --[[
-- * Returns true if the object is a plain object.
-- * @method isPlainObject
-- * @param {object} obj
-- * @return {boolean} True if the object is a plain object, otherwise false
-- ]]--
-- Common.isPlainObject = function(obj) {
-- 	return typeof obj === 'object' && obj.constructor === Object;
-- };
--
-- --[[
-- * Returns true if the object is a string.
-- * @method isString
-- * @param {object} obj
-- * @return {boolean} True if the object is a string, otherwise false
-- ]]--
-- Common.isString = function(obj) {
-- 	return toString.call(obj) === '[object String]';
-- };

--
-- --[[
-- * Returns the current timestamp since the time origin (e.g. from page load).
-- * The result will be high-resolution including decimal places if available.
-- * @method now
-- * @return {number} the current timestamp
-- ]]--
-- Common.now = function() {
-- 	if (typeof window !== 'undefined' && window.performance) {
-- 		if (window.performance.now) {
-- 			return window.performance.now();
-- 		} else if (window.performance.webkitNow) {
-- 			return window.performance.webkitNow();
-- 		}
-- 	}
--
-- 	return (new Date()) - Common._nowStartTime;
-- };

--
-- --[[
-- * Takes a directed graph and returns the partially ordered set of vertices in topological order.
-- * Circular dependencies are allowed.
-- * @method topologicalSort
-- * @param {object} graph
-- * @return {array} Partially ordered set of vertices in topological order.
-- ]]--
-- Common.topologicalSort = function(graph) {
-- 	// https://github.com/mgechev/javascript-algorithms
-- 	// Copyright (c) Minko Gechev (MIT license)
-- 	// Modifications: tidy formatting and naming
-- 	var result = [],
-- 	visited = [],
-- 	temp = [];
--
-- 	for (var node in graph) {
-- 		if (!visited[node] && !temp[node]) {
-- 			Common._topologicalSort(node, visited, temp, graph, result);
-- 		}
-- 	}
--
-- 	return result;
-- };
--
-- Common._topologicalSort = function(node, visited, temp, graph, result) {
-- 	var neighbors = graph[node] || [];
-- 	temp[node] = true;
--
-- 	for (var i = 0; i < neighbors.length; i += 1) {
-- 		var neighbor = neighbors[i];
--
-- 		if (temp[neighbor]) {
-- 			// skip circular dependencies
-- 			continue;
-- 		}
--
-- 		if (!visited[neighbor]) {
-- 			Common._topologicalSort(neighbor, visited, temp, graph, result);
-- 		}
-- 	}
--
-- 	temp[node] = false;
-- 	visited[node] = true;
--
-- 	result.push(node);
-- };

-- --[[
-- * Takes _n_ functions as arguments and returns a new function that calls them in order.
-- * The arguments applied when calling the new function will also be applied to every function passed.
-- * The value of `this` refers to the last value returned in the chain that was not `undefined`.
-- * Therefore if a passed function does not return a value, the previously returned value is maintained.
-- * After all passed functions have been called the new function returns the last returned value (if any).
-- * If any of the passed functions are a chain, then the chain will be flattened.
-- * @method chain
-- * @param ...funcs {function} The functions to chain.
-- * @return {function} A new function that calls the passed functions in order.
-- ]]--
-- Common.chain = function() {
-- var funcs = [];
--
-- for (var i = 0; i < arguments.length; i += 1) {
-- var func = arguments[i];
--
-- if (func._chained) {
-- // flatten already chained functions
-- funcs.push.apply(funcs, func._chained);
-- } else {
-- funcs.push(func);
-- }
-- }
--
-- var chain = function() {
-- // https://github.com/GoogleChrome/devtools-docs/issues/53#issuecomment-51941358
-- var lastResult,
-- args = new Array(arguments.length);
--
-- for (var i = 0, l = arguments.length; i < l; i++) {
-- args[i] = arguments[i];
-- }
--
-- for (i = 0; i < funcs.length; i += 1) {
-- var result = funcs[i].apply(lastResult, args);
--
-- if (typeof result !== 'undefined') {
-- lastResult = result;
-- }
-- }
--
-- return lastResult;
-- };
--
-- chain._chained = funcs;
--
-- return chain;
-- };
--
-- --[[
-- * Chains a function to excute before the original function on the given `path` relative to `base`.
-- * See also docs for `Common.chain`.
-- * @method chainPathBefore
-- * @param {} base The base object
-- * @param {string} path The path relative to `base`
-- * @param {function} func The function to chain before the original
-- * @return {function} The chained function that replaced the original
-- ]]--
-- Common.chainPathBefore = function(base, path, func) {
-- return Common.set(base, path, Common.chain(
-- func,
-- Common.get(base, path)
-- ));
-- };
--
-- --[[
-- * Chains a function to excute after the original function on the given `path` relative to `base`.
-- * See also docs for `Common.chain`.
-- * @method chainPathAfter
-- * @param {} base The base object
-- * @param {string} path The path relative to `base`
-- * @param {function} func The function to chain after the original
-- * @return {function} The chained function that replaced the original
-- ]]--
-- Common.chainPathAfter = function(base, path, func) {
-- 	return Common.set(base, path, Common.chain(
-- 		Common.get(base, path),
-- 		func
-- 	));
-- };
-- })();
--