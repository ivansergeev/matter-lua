--[[
* The `Matter.Composite` module contains methods for creating and manipulating composite bodies.
* A composite body is a collection of `Matter.Body`, `Matter.Constraint` and other `Matter.Composite`, therefore composites form a tree structure.
* It is important to use the functions in this module to modify composites, rather than directly modifying their properties.
* Note that the `Matter.World` object is also a type of `Matter.Composite` and as such all composite methods here can also operate on a `Matter.World`.
*
* See the included usage [examples](https:--github.com/liabru/matter-js/tree/master/examples).
*
* @class Composite
]]--

class('Composite').extends()

--[[
 * Creates a new composite. The options parameter is an object that specifies any properties you wish to override the defaults.
 * See the properites section below for detailed information on what you can pass via the `options` object.
 * @method create
 * @param {} [options]
 * @return {composite} A new composite
 ]]--

function Composite.create(options)
	return Common.extend({
		id = Common.nextId(),
		type = 'composite',
		parent = null,
		isModified = false,
		bodies = {},
		constraints = {},
		composites = {},
		label = 'Composite',
		plugin = {}
	}, options)
end

--[[
 * Sets the composite's `isModified` flag.
 * If `updateParents` is true, all parents will be set (default: false).
 * If `updateChildren` is true, all children will be set (default: false).
 * @method setModified
 * @param {composite} composite
 * @param {boolean} isModified
 * @param {boolean} [updateParents=false]
 * @param {boolean} [updateChildren=false]
 ]]--

function Composite.setModified(composite, isModified, updateParents, updateChildren)

	composite.isModified = isModified

	if (updateParents and composite.parent) then
		Composite.setModified(composite.parent, isModified, updateParents, updateChildren)
	end

	if (updateChildren) then
		local n = #composite.composites
		for i = 1, n do
			local childComposite = composite.composites[i]
			Composite.setModified(childComposite, isModified, updateParents, updateChildren)
		end
	end
end

--[[
 * Generic add function. Adds one or many body(s), constraint(s) or a composite(s) to the given composite.
 * Triggers `beforeAdd` and `afterAdd` events on the `composite`.
 * @method add
 * @param {composite} composite
 * @param {} object
 * @return {composite} The original composite with the objects added
 ]]--
function Composite.add(composite, object)
	local objects = table.clone(object)
	local n = #objects
	local switch = {
		body = function (obj)
			-- skip adding compound parts
			if (obj.parent ~= obj) then
				Common.warn('Composite.add: skipped adding a compound body part (you must add its parent instead)')
			end

			Composite.addBody(composite, obj)
		end,
		constraint = function (obj)
			Composite.addConstraint(composite, obj)
		end,
		composite = function (obj)
			Composite.addComposite(composite, obj)
		end,
		mouseConstraint = function (obj)
			Composite.addConstraint(composite, obj.constraint)
		end,
	}

	Events.trigger(composite, 'beforeAdd', { object = object })

	for i = 1, n do
		switch[objects[i].type](objects[i])
	end

	Events.trigger(composite, 'afterAdd', { object = object })

	return composite
end

--[[
 * Generic remove function. Removes one or many body(s), constraint(s) or a composite(s) to the given composite.
 * Optionally searching its children recursively.
 * Triggers `beforeRemove` and `afterRemove` events on the `composite`.
 * @method remove
 * @param {composite} composite
 * @param {} object
 * @param {boolean} [deep=false]
 * @return {composite} The original composite with the objects removed
 ]]--
function Composite.remove(composite, object, deep)

	local objects = table.clone(object)
	local n = #objects
	local switch = {
		body = function (obj)
			Composite.removeBody(composite, obj, deep)
		end,
		constraint = function (obj)
			Composite.removeConstraint(composite, obj, deep)
		end,
		composite = function (obj)
			Composite.removeComposite(composite, obj, deep)
		end,
		mouseConstraint = function (obj)
			Composite.removeConstraint(composite, obj.constraint)
		end,
	}

	Events.trigger(composite, 'beforeRemove', { object = object })

	for i = 1, n do
		switch[objects[i].type](objects[i])
	end

	Events.trigger(composite, 'afterRemove', { object = object })

	return composite
end

--[[
 * Adds a composite to the given composite.
 * @private
 * @method addComposite
 * @param {composite} compositeA
 * @param {composite} compositeB
 * @return {composite} The original compositeA with the objects from compositeB added
 ]]--

function Composite.addComposite(compositeA, compositeB)
	table.insert(compositeA, compositeB)
	compositeB.parent = compositeA
	Composite.setModified(compositeA, true, true, false)
	return compositeA
end

--[[
 * Removes a composite from the given composite, and optionally searching its children recursively.
 * @private
 * @method removeComposite
 * @param {composite} compositeA
 * @param {composite} compositeB
 * @param {boolean} [deep=false]
 * @return {composite} The original compositeA with the composite removed
 ]]--

function Composite.removeComposite(compositeA, compositeB, deep)

	for key, item in pairs(compositeA.composites) do
		if (item == compositeB) then
			Composite.removeCompositeAt(compositeA, key)
			-- Composite.setModified(compositeA, true, true, false)
			break
		end
	end

	if (deep) then
		local n = #compositeA.composites

		for i = 1, n do
			Composite.removeComposite(compositeA.composites[i], compositeB, true)
		end
	end

	return compositeA
end

--[[
 * Removes a composite from the given composite.
 * @private
 * @method removeCompositeAt
 * @param {composite} composite
 * @param {number} position
 * @return {composite} The original composite with the composite removed
 ]]--
function Composite.removeCompositeAt(composite, position)
	table.remove(composite.composites, position)
	Composite.setModified(composite, true, true, false)
	return composite
end

--[[
 * Adds a body to the given composite.
 * @private
 * @method addBody
 * @param {composite} composite
 * @param {body} body
 * @return {composite} The original composite with the body added
 ]]--

function Composite.addBody(composite, body)
	table.insert(composite.bodies, body)
	Composite.setModified(composite, true, true, false)
	return composite
end

--[[
 * Removes a body from the given composite, and optionally searching its children recursively.
 * @private
 * @method removeBody
 * @param {composite} composite
 * @param {body} body
 * @param {boolean} [deep=false]
 * @return {composite} The original composite with the body removed
 ]]--
function Composite.removeBody(composite, body, deep)

	for key, item in pairs(compositeA.bodies) do
		if (item == body) then
			Composite.removeBodyAt(composite, key)
			-- Composite.setModified(composite, true, true, false)
			break
		end
	end

	if (deep) then
		local n = #composite.composites
		for i = 1, n do
			Composite.removeBody(composite.composites[i], body, true)
		end
	end

	return composite
end

--[[
 * Removes a body from the given composite.
 * @private
 * @method removeBodyAt
 * @param {composite} composite
 * @param {number} position
 * @return {composite} The original composite with the body removed
 ]]--
function Composite.removeBodyAt(composite, position)
	table.remove(composite.bodies, position)
	Composite.setModified(composite, true, true, false)
	return composite
end

--[[
 * Adds a constraint to the given composite.
 * @private
 * @method addConstraint
 * @param {composite} composite
 * @param {constraint} constraint
 * @return {composite} The original composite with the constraint added
 ]]--
function Composite.addConstraint(composite, constraint)
	table.insert(composite.constraints, constraint)
	Composite.setModified(composite, true, true, false)
	return composite
end

--[[
 * Removes a constraint from the given composite, and optionally searching its children recursively.
 * @private
 * @method removeConstraint
 * @param {composite} composite
 * @param {constraint} constraint
 * @param {boolean} [deep=false]
 * @return {composite} The original composite with the constraint removed
 ]]--

function Composite.removeConstraint(composite, constraint, deep)

	for key, item in pairs(compositeA.constraints) do
		if (item == constraint) then
			Composite.removeConstraintAt(composite, key)
			break
		end
	end

	if (deep) then
		local n = #composite.composites
		for i = 1, n do
			Composite.removeConstraint(composite.composites[i], constraint, true)
		end
	end

	return composite
end

--[[
 * Removes a body from the given composite.
 * @private
 * @method removeConstraintAt
 * @param {composite} composite
 * @param {number} position
 * @return {composite} The original composite with the constraint removed
 ]]--
function Composite.removeConstraintAt(composite, position)
	table.remove(composite.constraints, position)
	Composite.setModified(composite, true, true, false)
	return composite
end

--[[
 * Removes all bodies, constraints and composites from the given composite.
 * Optionally clearing its children recursively.
 * @method clear
 * @param {composite} composite
 * @param {boolean} keepStatic
 * @param {boolean} [deep=false]
 ]]--

function Composite.clear(composite, keepStatic, deep)

	if (deep) then
		local n = #composite.composites
		for i = 1, n do
			Composite.clear(composite.composites[i], keepStatic, true)
		end
	end

	if (keepStatic) then
		composite.bodies = table.filter(composite.bodies, function(body) return body.isStatic end)
	else
		composite.bodies = {}
	end

	composite.constraints = {}
	composite.composites = {}
	Composite.setModified(composite, true, true, false)

	return composite
end

--[[
 * Returns all bodies in the given composite, including all bodies in its children, recursively.
 * @method allBodies
 * @param {composite} composite
 * @return {body[]} All the bodies
 ]]--
function Composite.allBodies(composite)
	local bodies = table.clone(composite.bodies)
	local n = #composite.composites

	for i = 1, n do
		bodies = table.union(bodies, Composite.allBodies(composite.composites[i]))
	end

	return bodies
end

--[[
 * Returns all constraints in the given composite, including all constraints in its children, recursively.
 * @method allConstraints
 * @param {composite} composite
 * @return {constraint[]} All the constraints
 ]]--
function Composite.allConstraints(composite)
	local constraints = table.clone(composite.constraints)
	local n = #composite.composites

	for i = 1, n do
		constraints = table.union(constraints, Composite.allConstraints(composite.composites[i]))
	end

	return constraints
end

--[[
 * Returns all composites in the given composite, including all composites in its children, recursively.
 * @method allComposites
 * @param {composite} composite
 * @return {composite[]} All the composites
 ]]--

function Composite.allComposites(composite)
	local composites = table.clone(composite.composites)
	local n = #composite.composites

	for i = 1, n do
		composites = table.union(composites, Composite.allComposites(composite.composites[i]))
	end

	return composites
end

--[[
 * Searches the composite recursively for an object matching the type and id supplied, null if not found.
 * @method get
 * @param {composite} composite
 * @param {number} id
 * @param {string} type
 * @return {object} The requested object, if found
 ]]--

function Composite.get(composite, id, type)

	local switch = {
			body = function ()
				return Composite.allBodies(composite)
			end,
			constraint = function ()
				return  Composite.allConstraints(composite)
			end,
			composite = function ()
				local result = 	Composite.allComposites(composite)
				return table.union(result, composite)
			end,
		}

	local objects = switch[type]()

	if (not objects) then
		return nil
	end

	local object = table.filter(objects, function(object)
		return tostring(object.id) == tostring(id)
	end)

	return #object == 0 and nil or object[1]
end

--[[
 * Moves the given object(s) from compositeA to compositeB (equal to a remove followed by an add).
 * @method move
 * @param {compositeA} compositeA
 * @param {object[]} objects
 * @param {compositeB} compositeB
 * @return {composite} Returns compositeA
 ]]--

function Composite.move(compositeA, objects, compositeB)
	Composite.remove(compositeA, objects)
	Composite.add(compositeB, objects)
	return compositeA
end

--[[
 * Assigns new ids for all objects in the composite, recursively.
 * @method rebase
 * @param {composite} composite
 * @return {composite} Returns composite
 ]]--

function Composite.rebase(composite)
	local objects = Composite.allBodies(composite)
	objects = table.union(objects, Composite.allConstraints(composite))
	objects = table.union(objects, Composite.allComposites(composite))

	local n = #objects

	for i = 1, n do
		objects[i].id = Common.nextId()
	end

	Composite.setModified(composite, true, true, false)

	return composite
end

--[[
 * Translates all children in the composite by a given vector relative to their current positions,
 * without imparting any velocity.
 * @method translate
 * @param {composite} composite
 * @param {vector} translation
 * @param {bool} [recursive=true]
 ]]--

function Composite.translate(composite, translation, recursive)

	local bodies = recursive and Composite.allBodies(composite) or composite.bodies
	local n = #bodies

	for i = 1, n do
		Body.translate(bodies[i], translation)
	end

	Composite.setModified(composite, true, true, false)

	return composite
end

--[[
 * Rotates all children in the composite by a given angle about the given point, without imparting any angular velocity.
 * @method rotate
 * @param {composite} composite
 * @param {number} rotation
 * @param {vector} point
 * @param {bool} [recursive=true]
 ]]--
function Composite.rotate(composite, rotation, point, recursive)
	local cos, sin = math.cos(rotation), math.sin(rotation)
	local bodies = recursive and Composite.allBodies(composite) or composite.bodies
	local n = #bodies

	for i = 1, n do
		local body = bodies[i]
		local dx = body.position.x - point.x
		local dy = body.position.y - point.y

		Body.setPosition(body, {
			x = point.x + (dx * cos - dy * sin),
			y = point.y + (dx * sin + dy * cos)
		})

		Body.rotate(body, rotation)
	end

	Composite.setModified(composite, true, true, false)

	return composite
end

--[[
 * Scales all children in the composite, including updating physical properties (mass, area, axes, inertia), from a world-space point.
 * @method scale
 * @param {composite} composite
 * @param {number} scaleX
 * @param {number} scaleY
 * @param {vector} point
 * @param {bool} [recursive=true]
 ]]--
function Composite.scale(composite, scaleX, scaleY, point, recursive)
	local bodies = recursive and Composite.allBodies(composite) or composite.bodies
	local n = #bodies

	for i = 1, n do
		local body = bodies[i]
		local dx = body.position.x - point.x
		local dy = body.position.y - point.y

		Body.setPosition(body, {
			x = point.x + dx * scaleX,
			y = point.y + dy * scaleY
		})

		Body.scale(body, scaleX, scaleY)
	end

	Composite.setModified(composite, true, true, false)

	return composite
end

--[[
 * Returns the union of the bounds of all of the composite's bodies.
 * @method bounds
 * @param {composite} composite The composite.
 * @returns {bounds} The composite bounds.
 ]]--

function Composite.bounds(composite)
	local bodies = Composite.allBodies(composite)
	local vertices = {}
	local n = #bodies

	for i = 1, n do
		local body = bodies[i]
		table.insert(vertices, body.bounds.min)
		table.insert(vertices, body.bounds.max)
	end

	return Bounds.create(vertices)
end

--[[
*
*  Events Documentation
*
]]--

--[[
* Fired when a call to `Composite.add` is made, before objects have been added.
*
* @event beforeAdd
* @param {} event An event object
* @param {} event.object The object(s) to be added (may be a single body, constraint, composite or a mixed array of these)
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired when a call to `Composite.add` is made, after objects have been added.
*
* @event afterAdd
* @param {} event An event object
* @param {} event.object The object(s) that have been added (may be a single body, constraint, composite or a mixed array of these)
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired when a call to `Composite.remove` is made, before objects have been removed.
*
* @event beforeRemove
* @param {} event An event object
* @param {} event.object The object(s) to be removed (may be a single body, constraint, composite or a mixed array of these)
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired when a call to `Composite.remove` is made, after objects have been removed.
*
* @event afterRemove
* @param {} event An event object
* @param {} event.object The object(s) that have been removed (may be a single body, constraint, composite or a mixed array of these)
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
*
*  Properties Documentation
*
]]--

--[[
 * An integer `Number` uniquely identifying number generated in `Composite.create` by `Common.nextId`.
 *
 * @property id
 * @type number
 ]]--

--[[
 * A `String` denoting the type of object.
 *
 * @property type
 * @type string
 * @default "composite"
 * @readOnly
 ]]--

--[[
 * An arbitrary `String` name to help the user identify and manage composites.
 *
 * @property label
 * @type string
 * @default "Composite"
 ]]--

--[[
 * A flag that specifies whether the composite has been modified during the current step.
 * Most `Matter.Composite` methods will automatically set this flag to `true` to inform the engine of changes to be handled.
 * If you need to change it manually, you should use the `Composite.setModified` method.
 *
 * @property isModified
 * @type boolean
 * @default false
 ]]--

--[[
 * The `Composite` that is the parent of this composite. It is automatically managed by the `Matter.Composite` methods.
 *
 * @property parent
 * @type composite
 * @default null
 ]]--

--[[
 * An array of `Body` that are _direct_ children of this composite.
 * To add or remove bodies you should use `Composite.add` and `Composite.remove` methods rather than directly modifying this property.
 * If you wish to recursively find all descendants, you should use the `Composite.allBodies` method.
 *
 * @property bodies
 * @type body[]
 * @default []
 ]]--

--[[
 * An array of `Constraint` that are _direct_ children of this composite.
 * To add or remove constraints you should use `Composite.add` and `Composite.remove` methods rather than directly modifying this property.
 * If you wish to recursively find all descendants, you should use the `Composite.allConstraints` method.
 *
 * @property constraints
 * @type constraint[]
 * @default []
 ]]--

--[[
 * An array of `Composite` that are _direct_ children of this composite.
 * To add or remove composites you should use `Composite.add` and `Composite.remove` methods rather than directly modifying this property.
 * If you wish to recursively find all descendants, you should use the `Composite.allComposites` method.
 *
 * @property composites
 * @type composite[]
 * @default []
 ]]--

--[[
 * An object reserved for storing plugin-specific properties.
 *
 * @property plugin
 * @type {}
 ]]--

