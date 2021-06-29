--[[
* The `Matter.Events` module contains methods to fire and listen to events on other objects.
*
* See the included usage [examples](https:--github.com/liabru/matter-js/tree/master/examples).
*
* @class Events
]]--

import 'matter/core/Common'

Events = {}
Events.__index = Events

--[[
 * Subscribes a callback function to the given object's `eventName`.
 * @method on
 * @param {} object
 * @param {string} eventNames
 * @param {function} callback
 ]]--

function Events.on(object, eventNames, callback)
	local names = eventNames:split(' ')
	local n = #names
	local name

	for i = 1, n do
		name = names[i]

		object.events = object.events or {}
		object.events[name] = object.events[name] or {}

		table.insert(object.events[name], callback)
	end

	return callback
end

--[[
 * Removes the given event callback. If no callback, clears all callbacks in `eventNames`. If no `eventNames`, clears all events.
 * @method off
 * @param {} object
 * @param {string} eventNames
 * @param {function} callback
 ]]--

function Events.off(object, eventNames, callback)

	if (not eventNames) then
		object.events = {}
		return
	end

	-- handle Events.off(object, callback)
	if (type(eventNames) == 'function') then
		callback = eventNames
		eventNames = Common.keys(object.events)

		-- join table with space
		local s = ''
		local n = #eventNames

		for i=1, n do
			s = (s ~= '' and s .. ' ' .. eventNames[i] or eventNames[i])
		end

		eventNames = s
	end

	local names = eventNames:split(' ')
	local n = #names

	for i = 1, n do

		local callbacks = object.events[names[i]]
		local newCallbacks = {}

		if (callback and callbacks) then
			local c = #callbacks
			for j = 1, c do
				if (callbacks[j] ~= callback) then
					table.insert(newCallbacks, callbacks[j])
				end
			end
		end

		object.events[names[i]] = newCallbacks
	end
end

--[[
 * Fires all the callbacks subscribed to the given object's `eventName`, in the order they subscribed, if any.
 * @method trigger
 * @param {} object
 * @param {string} eventNames
 * @param {} event
 ]]--

function Events.trigger(object, eventNames, event)
	local names,
		name,
		callbacks,
		eventClone

	local events = object.events
	local e = Common.keys(events)
	e = #e

	if (events and e > 0) then

		if (not event) then
			event = {}
		end

		names = eventNames:split(' ')

		local n = #names

		for i = 1, n do
			name = names[i]
			callbacks = events[name]

			if (callbacks) then
				eventClone = Common.clone(event, false)
				eventClone.name = name
				eventClone.source = object

				local c = #callbacks
				for j = 1, c do
					callbacks[j](object, table.unpack(eventClone))
				end
			end
		end
	end
end
