--[[
* The `Matter.Body` module contains methods for creating and manipulating body models.
* A `Matter.Body` is a rigid body that can be simulated by a `Matter.Engine`.
* Factories for commonly used body configurations (such as rectangles, circles and other polygons) can be found in the module `Matter.Bodies`.
*
* See the included usage [examples](https:--github.com/liabru/matter-js/tree/master/examples).

* @class Body
]]--


import 'matter/geometry/Vertices'
import 'matter/geometry/Vector'
import 'matter/core/Sleeping'
import 'matter/render/Render'
import 'matter/core/Common'
import 'matter/geometry/Bounds'
import 'matter/geometry/Axes'


Body = {}
Body.__index = Body

Body._inertiaScale = 4
Body._nextCollidingGroupId = 1
Body._nextNonCollidingGroupId = -1
Body._nextCategory = 0x0001


--[[
* Initialises body properties.
* @method _initProperties
* @private
* @param {body} body
* @param {} [options]
]]--

local function  _initProperties(body, options)

	-- print('_initProperties #', body.id)

	-- if (body.id == 12) then
		-- print('vertices #', body.id)
		-- printTable(body.vertices)
	-- end

	options = options or {}

	-- init required properties (order is important)

	Body.set(body, {
		bounds = body.bounds or Bounds.create(body.vertices),
		positionPrev = body.positionPrev or Vector.clone(body.position),
		anglePrev = body.anglePrev or body.angle,
		vertices = body.vertices,
		isStatic = body.isStatic,
		isSleeping = body.isSleeping,
		parent = body.parent or body,
	})

	-- !!! Very important update parts after update vertices. Props: area
	Body.set(body, {
		parts = body.parts or {body},
	})

	Vertices.rotate(body.vertices, body.angle, body.position)
	Axes.rotate(body.axes, body.angle)
	Bounds.update(body.bounds, body.vertices, body.velocity)

	-- allow options to override the automatically calculated properties

	Body.set(body, {
		axes = options.axes or body.axes,
		area = options.area or body.area,
		mass = options.mass or body.mass,
		inertia = options.inertia or body.inertia,
	})

	print('#', body.id, ' area: ', options.area, body.area)

	-- render properties

	body.render.sprite.xOffset += -(body.bounds.min.x - body.position.x) / (body.bounds.max.x - body.bounds.min.x)
	body.render.sprite.yOffset += -(body.bounds.min.y - body.position.y) / (body.bounds.max.y - body.bounds.min.y)

end


--[[
 * Creates a new rigid body model. The options parameter is an object that specifies any properties you wish to override the defaults.
 * All properties have default values, and many are pre-calculated automatically based on other properties.
 * Vertices must be specified in clockwise order.
 * See the properties section below for detailed information on what you can pass via the `options` object.
 * @method create
 * @param {} options
 * @return {body} body
 ]]--


function Body.create(options)

	--print('Body.create')

	local defaults = {
		id = Common.nextId(),
		type = 'body',
		label = 'Body',
		parts = {},
		plugin = {},
		angle = 0,
		-- vertices = Vertices.fromPath('L 0 0 L 40 0 L 40 40 L 0 40'),
		vertices = {},
		position = { x = 0, y = 0 },
		force = { x = 0, y = 0 },
		torque = 0,
		positionImpulse = { x = 0, y = 0 },
		constraintImpulse = { x = 0, y = 0, angle = 0 },
		totalContacts = 0,
		speed = 0,
		angularSpeed = 0,
		velocity = { x = 0, y = 0 },
		angularVelocity = 0,
		isSensor = false,
		isStatic = false,
		isSleeping = false,
		motion = 0,
		sleepThreshold = 60, -- default 60
		density = 0.001,
		restitution = 0,
		friction = 0.1,
		frictionStatic = 0.5,
		frictionAir = 0.01,
		collisionFilter = {
			category = 0x0001,
			mask = 0xFFFF, -- 0xFFFFFFFF
			group = 0
		},
		slop = 0.05, -- default 0.05
		timeScale = 1,
		render = {
			visible = true,
			opacity = 1,
			sprite = {
				xScale = 1,
				yScale = 1,
				xOffset = 0,
				yOffset = 0
			},
			lineWidth = 0
		},
		events = nil,
		bounds = nil,
		chamfer = nil,
		circleRadius = 0,
		positionPrev = nil,
		anglePrev = 0,
		parent = nil,
		axes = nil,
		area = 0,
		mass = 0,
		inertia = 0,
		_original = nil
	}

	if (not options.vertices) then
		-- print('Body.create: default vertices')
		-- defaults.vertices = Vertices.fromPath('L 0 0 L 40 0 L 40 40 L 0 40')
	end

	local body = Common.extend(defaults, options)
	_initProperties(body, options)

	return body
end


function Body.createWithParts(options)

	-- print('Body.createWithParts')

	local defaults = {
		id = Common.nextId(),
		type = 'body',
		label = 'Body',
		parts = options.parts,
		plugin = {},
		angle = 0,
		-- vertices = Vertices.fromPath('L 0 0 L 40 0 L 40 40 L 0 40'),
		vertices = {},
		position = { x = 0, y = 0 },
		force = { x = 0, y = 0 },
		torque = 0,
		positionImpulse = { x = 0, y = 0 },
		constraintImpulse = { x = 0, y = 0, angle = 0 },
		totalContacts = 0,
		speed = 0,
		angularSpeed = 0,
		velocity = { x = 0, y = 0 },
		angularVelocity = 0,
		isSensor = false,
		isStatic = options.isStatic,
		isSleeping = false,
		motion = 0,
		sleepThreshold = 60, -- default 60
		density = 0.001,
		restitution = 0,
		friction = 0.1,
		frictionStatic = 0.5,
		frictionAir = 0.01,
		collisionFilter = {
			category = 0x0001,
			mask = 0xFFFF, -- 0xFFFFFFFF
			group = 0
		},
		slop = 0.05, -- default 0.05
		timeScale = 1,
		render = {
			visible = true,
			opacity = 1,
			sprite = {
				xScale = 1,
				yScale = 1,
				xOffset = 0,
				yOffset = 0
			},
			lineWidth = 0
		},
		events = nil,
		bounds = nil,
		chamfer = nil,
		circleRadius = 0,
		positionPrev = {
			x = 0,
			y = 0
		},
		anglePrev = 0,
		parent = nil,
		axes = nil,
		area = 0,
		mass = options.mass,
		inertia = 0,
		_original = nil,
	}

	if (not options.vertices) then
		print('Body.create: default vertices')
		-- defaults.vertices = Vertices.fromPath('L 0 0 L 40 0 L 40 40 L 0 40')
	end

	-- local body = Common.extend(defaults, options)

	local body = defaults
	_initProperties(body, options)

	return body
end

--[[
 * Returns the next unique group index for which bodies will collide.
 * If `isNonColliding` is `true`, returns the next unique group index for which bodies will _not_ collide.
 * See `body.collisionFilter` for more information.
 * @method nextGroup
 * @param {bool} [isNonColliding=false]
 * @return {Number} Unique group index
 ]]--

function Body.nextGroup(isNonColliding)
	if (isNonColliding) then
		Body._nextNonCollidingGroupId -= 1
	else
		Body._nextCollidingGroupId += 1
	end

	return 	Body._nextCollidingGroupId
end

--[[
 * Returns the next unique category bitfield (starting after the initial default category `0x0001`).
 * There are 32 available. See `body.collisionFilter` for more information.
 * @method nextCategory
 * @return {Number} Unique category bitfield
 ]]--

function Body.nextCategory()
	Body._nextCategory = Body._nextCategory << 1
	return Body._nextCategory
end


--[[
 * Given a property and a value (or map of), sets the property(s) on the body, using the appropriate setter functions if they exist.
 * Prefer to use the actual setter functions in performance critical situations.
 * @method set
 * @param {body} body
 * @param {} settings A property name (or map of properties and values) to set on the body.
 * @param {} value The value to set if `settings` is a single property name.
 ]]--

function Body.set(body, settings, value)

	--print('Body.set')
	--printTable(settings)

	local property

	if (type(settings) == 'string')  then
		property = settings
		settings = {}
		settings[property] = value
	end

	local switch = {
		isStatic = function(val)
			Body.setStatic(body, val)
			return true
		end,
		isSleeping = function(val)
			Sleeping.set(body, val)
			return true
		end,
		mass = function(val)
			Body.setMass(body, val)
			return true
		end,
		density = function(val)
			Body.setDensity(body, val)
			return true
		end,
		inertia = function(val)
			Body.setInertia(body, val)
			return true
		end,
		vertices = function(val)
			Body.setVertices(body, val)
			return true
		end,
		position = function(val)
			Body.setPosition(body, val)
			return true
		end,
		angle = function(val)
			Body.setAngle(body, val)
			return true
		end,
		velocity = function(val)
			Body.setVelocity(body, val)
			return true
		end,
		angularVelocity = function(val)
			Body.setAngularVelocity(body, val)
			return true
		end,
		parts = function(val)
			Body.setParts(body, val)
			return true
		end,
		centre = function(val)
			Body.setCentre(body, val)
			return true
		end,
	}

	for prop, val in pairs(settings)  do
		if (not switch[prop] or not switch[prop](val, prop)) then
			-- print('set:', prop, val)
			body[prop] = val
		end
	end

end

--[[
 * Sets the body as static, including isStatic flag and setting mass and inertia to Infinity.
 * @method setStatic
 * @param {body} body
 * @param {bool} isStatic
 ]]--

function Body.setStatic(body, isStatic)

	-- print('Body.setStatic', (body and body.id or '???'))
	local n = #body.parts

	for i = 1, n do

		local part = body.parts[i]
		part.isStatic = isStatic

		if (isStatic)  then
			part._original = {
				restitution = part.restitution,
				friction = part.friction,
				mass = part.mass,
				inertia = part.inertia,
				density = part.density,
				inverseMass = part.inverseMass,
				inverseInertia = part.inverseInertia,
			}

			part.restitution = 0
			part.friction = 1
			part.mass = math.huge
			part.inertia = math.huge
			part.density = math.huge
			part.inverseMass = 0
			part.inverseInertia = 0

			if (not part.positionPrev) then
				part.positionPrev = {}
			end

			part.positionPrev.x = part.position.x
			part.positionPrev.y = part.position.y
			part.anglePrev = part.angle
			part.angularVelocity = 0
			part.speed = 0
			part.angularSpeed = 0
			part.motion = 0
		elseif (part._original)  then
			part.restitution = part._original.restitution
			part.friction = part._original.friction
			part.mass = part._original.mass
			part.inertia = part._original.inertia
			part.density = part._original.density
			part.inverseMass = part._original.inverseMass
			part.inverseInertia = part._original.inverseInertia

			part._original = nil
		end
	end
end

--[[
 * Sets the mass of the body. Inverse mass, density and inertia are automatically updated to reflect the change.
 * @method setMass
 * @param {body} body
 * @param {number} mass
 ]]--
function Body.setMass(body, mass)

	-- print('Body.setMass #', body.id, mass)

	-- FIX
	-- the mass of the static object continued to be calculated
	-- in the js version, it is `Infinity`

	-- if (body.isStatic) then
	-- 	mass = math.huge
	-- end

	local moment = body.inertia / (body.mass / 6)

	body.inertia = moment * (mass / 6)
	body.inverseInertia = 1 / body.inertia
	body.mass = mass
	body.inverseMass = 1 / body.mass
	body.density = body.mass / body.area

	-- FIX
	-- the mass of the static object continued to be calculated
	-- in the js version, it is `Infinity`

	if (body.isStatic) then
		body.mass = body.mass or math.huge
		-- body.mass = math.huge
		body.inertia = math.huge
		body.inverseInertia = 1 / body.inertia
	end
end

--[[
 * Sets the density of the body. Mass and inertia are automatically updated to reflect the change.
 * @method setDensity
 * @param {body} body
 * @param {number} density
 ]]--
function Body.setDensity(body, density)
	Body.setMass(body, density * body.area)
	body.density = density
end

--[[
 * Sets the moment of inertia (i.e. second moment of area) of the body.
 * Inverse inertia is automatically updated to reflect the change. Mass is not changed.
 * @method setInertia
 * @param {body} body
 * @param {number} inertia
 ]]--

function Body.setInertia(body, inertia)

	-- print('Body.setInertia #', body.id, inertia)

	if (body.isStatic) then
		inertia = math.huge
	end

	body.inertia = inertia
	body.inverseInertia = 1 / body.inertia
end

--[[
 * Sets the body's vertices and updates body properties accordingly, including inertia, area and mass (with respect to `body.density`).
 * Vertices will be automatically transformed to be orientated around their centre of mass as the origin.
 * They are then automatically translated to world space based on `body.position`.
 *
 * The `vertices` argument should be passed as an array of `Matter.Vector` points (or a `Matter.Vertices` array).
 * Vertices must form a convex hull, concave hulls are not supported.
 *
 * @method setVertices
 * @param {body} body
 * @param {vector[]} vertices
 ]]--
function Body.setVertices(body, vertices)

	-- print('Body.setVertices #', body.id)
	-- printTable(body.vertices)

	-- change vertices
	if (vertices[1] and vertices[1].body == body)  then
		body.vertices = vertices
	else
		body.vertices = Vertices.create(vertices, body)
	end


	-- update properties
	body.axes = Axes.fromVertices(body.vertices)
	body.area = Vertices.area(body.vertices)

	Body.setMass(body, body.density * body.area)

	-- orient vertices around the centre of mass at origin (0, 0)
	local centre = Vertices.centre(body.vertices)

	Vertices.translate(body.vertices, centre, -1)

	-- update inertia while vertices are at origin (0, 0)

	Body.setInertia(body, Body._inertiaScale * Vertices.inertia(body.vertices, body.mass))

	-- update geometry
	Vertices.translate(body.vertices, body.position)

	Bounds.update(body.bounds, body.vertices, body.velocity)

end


--[[
 * Sets the parts of the `body` and updates mass, inertia and centroid.
 * Each part will have its parent set to `body`.
 * By default the convex hull will be automatically computed and set on `body`, unless `autoHull` is set to `false.`
 * Note that this method will ensure that the first part in `body.parts` will always be the `body`.
 * @method setParts
 * @param {body} body
 * @param [body] parts
 * @param {bool} [autoHull=true]
 ]]--

function Body.setParts(body, parts, autoHull)

	-- print('Body.setParts #', body.id, #body.parts)

	-- add all the parts, ensuring that the first part is always the parent body
	parts = table.deepclone2(parts)

	body.parts = {}
	table.insert(body.parts, body)

	body.parent = body

	local n = #parts

	for i = 1, n do
		local part = parts[i]
		if (part ~= body)  then
			part.parent = body
			table.insert(body.parts, part)
		end
	end

	if (#body.parts == 1) then
		return
	end

	autoHull = type(autoHull) ~= 'nil' and autoHull or true

	-- find the convex hull of all parts to set on the parent body
	if (autoHull)  then

		local vertices = {}
		for i = 1, n do
			vertices = table.concat(vertices, parts[i].vertices)
		end

		Vertices.clockwiseSort(vertices)

		local hull = Vertices.hull(vertices)
		local hullCentre = Vertices.centre(hull)

		Body.setVertices(body, hull)
		Vertices.translate(body.vertices, hullCentre)
	end

	-- sum the properties of all compound parts of the parent body
	local total = Body._totalProperties(body)

	body.area = total.area
	body.parent = body
	body.position.x = total.centre.x
	body.position.y = total.centre.y
	body.positionPrev.x = total.centre.x
	body.positionPrev.y = total.centre.y

	Body.setMass(body, total.mass)
	Body.setInertia(body, total.inertia)
	Body.setPosition(body, total.centre)

end

--[[
 * Set the centre of mass of the body.
 * The `centre` is a vector in world-space unless `relative` is set, in which case it is a translation.
 * The centre of mass is the point the body rotates about and can be used to simulate non-uniform density.
 * This is equal to moving `body.position` but not the `body.vertices`.
 * Invalid if the `centre` falls outside the body's convex hull.
 * @method setCentre
 * @param {body} body
 * @param {vector} centre
 * @param {bool} relative
 ]]--
function Body.setCentre(body, centre, relative)

	--print('Body.setCentre #', body.id, centre, relative)

	if (not relative)  then
		body.positionPrev.x = centre.x - (body.position.x - body.positionPrev.x)
		body.positionPrev.y = centre.y - (body.position.y - body.positionPrev.y)
		body.position.x = centre.x
		body.position.y = centre.y
	else
		body.positionPrev.x += centre.x
		body.positionPrev.y += centre.y
		body.position.x += centre.x
		body.position.y += centre.y
	end
end

--[[
 * Sets the position of the body instantly. Velocity, angle, force etc. are unchanged.
 * @method setPosition
 * @param {body} body
 * @param {vector} position
 ]]--
function Body.setPosition(body, position)

	--print('Body.setPosition #')
	--printTable(body)
	--printTable(position)

	local delta = Vector.sub(position, body.position)

	body.positionPrev.x += delta.x
	body.positionPrev.y += delta.y
	local n = #body.parts
	for i = 1, n do
		local part = body.parts[i]
		part.position.x += delta.x
		part.position.y += delta.y
		Vertices.translate(part.vertices, delta)
		Bounds.update(part.bounds, part.vertices, body.velocity)
	end
end

--[[
 * Sets the angle of the body instantly. Angular velocity, position, force etc. are unchanged.
 * @method setAngle
 * @param {body} body
 * @param {number} angle
 ]]--
function Body.setAngle(body, angle)
	local delta = angle - body.angle
	body.anglePrev += delta
	local n = #body.parts

	for i = 1, n do
		local part = body.parts[i]
		part.angle += delta
		Vertices.rotate(part.vertices, delta, body.position)
		Axes.rotate(part.axes, delta)
		Bounds.update(part.bounds, part.vertices, body.velocity)
		if (i > 1)  then
			Vector.rotateAbout(part.position, delta, body.position, part.position)
		end
	end
end

--[[
 * Sets the linear velocity of the body instantly. Position, angle, force etc. are unchanged. See also `Body.applyForce`.
 * @method setVelocity
 * @param {body} body
 * @param {vector} velocity
 ]]--

function Body.setVelocity(body, velocity)
	body.positionPrev.x = body.position.x - velocity.x
	body.positionPrev.y = body.position.y - velocity.y
	body.velocity.x = velocity.x
	body.velocity.y = velocity.y
	body.speed = Vector.magnitude(body.velocity)
end

--[[
 * Sets the angular velocity of the body instantly. Position, angle, force etc. are unchanged. See also `Body.applyForce`.
 * @method setAngularVelocity
 * @param {body} body
 * @param {number} velocity
 ]]--
function Body.setAngularVelocity(body, velocity)
	body.anglePrev = body.angle - velocity
	body.angularVelocity = velocity
	body.angularSpeed = math.abs(body.angularVelocity)
end

--[[
 * Moves a body by a given vector relative to its current position, without imparting any velocity.
 * @method translate
 * @param {body} body
 * @param {vector} translation
 ]]--
function Body.translate(body, translation)
	Body.setPosition(body, Vector.add(body.position, translation))
end

--[[
 * Rotates a body by a given angle relative to its current angle, without imparting any angular velocity.
 * @method rotate
 * @param {body} body
 * @param {number} rotation
 * @param {vector} [point]
 ]]--
function Body.rotate(body, rotation, point)
	if (not point)  then
		Body.setAngle(body, body.angle + rotation)
	else
		local cos, sin = math.cos(rotation), math.sin(rotation)
		local dx = body.position.x - point.x
		local dy = body.position.y - point.y

		Body.setPosition(body, {
			x = point.x + (dx * cos - dy * sin),
			y = point.y + (dx * sin + dy * cos),
		})

		Body.setAngle(body, body.angle + rotation)
	end
end

--[[
* Scales the body, including updating physical properties (mass, area, axes, inertia), from a world-space point (default is body centre).
* @method scale
* @param {body} body
* @param {number} scaleX
* @param {number} scaleY
* @param {vector} [point]
]]--

function Body.scale(body, scaleX, scaleY, point)

	local totalArea = 0
	local totalInertia = 0
	local n = #body.parts

	point = point or body.position

	for i = 1, n do
		local part = body.parts[i]

		-- scale vertices
		Vertices.scale(part.vertices, scaleX, scaleY, point)

		-- update properties
		part.axes = Axes.fromVertices(part.vertices)
		part.area = Vertices.area(part.vertices)
		Body.setMass(part, body.density * part.area)

		-- update inertia (requires vertices to be at origin)
		Vertices.translate(part.vertices, { x = -part.position.x, y = -part.position.y })
		Body.setInertia(part, Body._inertiaScale * Vertices.inertia(part.vertices, part.mass))
		Vertices.translate(part.vertices, { x = part.position.x, y = part.position.y })

		if (i > 0)  then
			totalArea += part.area
			totalInertia += part.inertia
		end

		-- scale position
		part.position.x = point.x + (part.position.x - point.x) * scaleX
		part.position.y = point.y + (part.position.y - point.y) * scaleY

		-- update bounds
		Bounds.update(part.bounds, part.vertices, body.velocity)
	end

	-- handle parent body
	if (n > 1)  then
		body.area = totalArea

		if (not body.isStatic)  then
			Body.setMass(body, body.density * totalArea)
			Body.setInertia(body, totalInertia)
		end
	end

	-- handle circles
	if (body.circleRadius)  then
		if (scaleX == scaleY)  then
			body.circleRadius *= scaleX
		else
			-- body is no longer a circle
			body.circleRadius = nil
		end
	end
end

--[[
 * Performs a simulation step for the given `body`, including updating position and angle using Verlet integration.
 * @method update
 * @param {body} body
 * @param {number} deltaTime
 * @param {number} timeScale
 * @param {number} correction
 ]]--

function Body.update(body, deltaTime, timeScale, correction)

	-- print('Body.update #', body.id)

	local deltaTimeSquared = math.pow(deltaTime * timeScale * body.timeScale, 2)

	-- from the previous step
	local frictionAir = 1 - body.frictionAir * timeScale * body.timeScale
	local velocityPrevX = body.position.x - body.positionPrev.x
	local velocityPrevY = body.position.y - body.positionPrev.y

	-- update velocity with Verlet integration

	body.velocity.x = (velocityPrevX * frictionAir * correction) + (body.force.x / body.mass) * deltaTimeSquared
	body.velocity.y = (velocityPrevY * frictionAir * correction) + (body.force.y / body.mass) * deltaTimeSquared

	body.positionPrev.x = body.position.x
	body.positionPrev.y = body.position.y

	body.position.x += body.velocity.x
	body.position.y += body.velocity.y

	-- update angular velocity with Verlet integration
	body.angularVelocity = ((body.angle - body.anglePrev) * frictionAir * correction) + (body.torque / body.inertia) * deltaTimeSquared
	body.anglePrev = body.angle
	body.angle += body.angularVelocity

	-- track speed and acceleration
	body.speed = Vector.magnitude(body.velocity)
	body.angularSpeed = math.abs(body.angularVelocity)

	-- transform the body geometry
	local n = #body.parts
	for i = 1, n do
		local part = body.parts[i]

		Vertices.translate(part.vertices, body.velocity)

		if (i > 1)  then

			part.position.x += body.velocity.x
			part.position.y += body.velocity.y

		end

		if (body.angularVelocity ~= 0) then
			Vertices.rotate(part.vertices, body.angularVelocity, body.position)
			Axes.rotate(part.axes, body.angularVelocity)
			if (i > 1)  then
				Vector.rotateAbout(part.position, body.angularVelocity, body.position, part.position)
			end
		end

		Bounds.update(part.bounds, part.vertices, body.velocity)
	end
end


--[[
 * Applies a force to a body from a given world-space position, including resulting torque.
 * @method applyForce
 * @param {body} body
 * @param {vector} position
 * @param {vector} force
 ]]--

function Body.applyForce(body, position, force)
	body.force.x += force.x
	body.force.y += force.y
	local offset = {
		x = position.x - body.position.x,
		y = position.y - body.position.y,
	}
	body.torque += offset.x * force.y - offset.y * force.x
end

--[[
 * Returns the sums of the properties of all compound parts of the parent body.
 * @method _totalProperties
 * @private
 * @param {body} body
 * @return {}
 ]]--

function Body._totalProperties(body)

	-- print('Body._totalProperties #', body.id)

	-- from equations at:
	-- https://ecourses.ou.edu/cgi-bin/ebook.cgi?doc=&topic=st&chap_sec=07.2&page=theory
	-- http://output.to/sideway/default.asp?qno=121100087

	local properties = {
		mass = 0,
		area = 0,
		inertia = 0,
		centre = {
			x = 0,
			y = 0
		}
	}

	-- sum the properties of all compound parts of the parent body
	local n = #body.parts

	for i = (n == 1 and 1 or 2), n do
		local part = body.parts[i]
		local mass = part.mass ~= math.huge and part.mass or 1

		properties.mass += mass
		properties.area += part.area
		properties.inertia += part.inertia
		properties.centre = Vector.add(properties.centre, Vector.mult(part.position, mass))
	end

	properties.centre = Vector.div(properties.centre, properties.mass)

	return properties
end

--[[
*
*  Events Documentation
*
]]--

--[[
* Fired when a body starts sleeping (where `this` is the body).
*
* @event sleepStart
* @this {body} The body that has started sleeping
* @param {} event An event object
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired when a body ends sleeping (where `this` is the body).
*
* @event sleepEnd
* @this {body} The body that has ended sleeping
* @param {} event An event object
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
*
*  Properties Documentation
*
]]--

--[[
 * An integer `Number` uniquely identifying number generated in `Body.create` by `Common.nextId`.
 *
 * @property id
 * @type number
 ]]--

--[[
 * A `String` denoting the type of object.
 *
 * @property type
 * @type string
 * @default "body"
 * @readOnly
 ]]--

--[[
 * An arbitrary `String` name to help the user identify and manage bodies.
 *
 * @property label
 * @type string
 * @default "Body"
 ]]--

--[[
 * An array of bodies that make up this body.
 * The first body in the array must always be a self reference to the current body instance.
 * All bodies in the `parts` array together form a single rigid compound body.
 * Parts are allowed to overlap, have gaps or holes or even form concave bodies.
 * Parts themselves should never be added to a `World`, only the parent body should be.
 * Use `Body.setParts` when setting parts to ensure correct updates of all properties.
 *
 * @property parts
 * @type body[]
 ]]--

--[[
 * An object reserved for storing plugin-specific properties.
 *
 * @property plugin
 * @type {}
 ]]--

--[[
 * A self reference if the body is _not_ a part of another body.
 * Otherwise this is a reference to the body that this is a part of.
 * See `body.parts`.
 *
 * @property parent
 * @type body
 ]]--

--[[
 * A `Number` specifying the angle of the body, in radians.
 *
 * @property angle
 * @type number
 * @default 0
 ]]--

--[[
 * An array of `Vector` objects that specify the convex hull of the rigid body.
 * These should be provided about the origin `(0, 0)`. E.g.
 *
 *	 [{ x: 0, y: 0 }, { x: 25, y: 50 }, { x: 50, y: 0 }]
 *
 * When passed via `Body.create`, the vertices are translated relative to `body.position` (i.e. world-space, and constantly updated by `Body.update` during simulation).
 * The `Vector` objects are also augmented with additional properties required for efficient collision detection.
 *
 * Other properties such as `inertia` and `bounds` are automatically calculated from the passed vertices (unless provided via `options`).
 * Concave hulls are not currently supported. The module `Matter.Vertices` contains useful methods for working with vertices.
 *
 * @property vertices
 * @type vector[]
 ]]--

--[[
 * A `Vector` that specifies the current world-space position of the body.
 *
 * @property position
 * @type vector
 * @default { x: 0, y: 0 }
 ]]--

--[[
 * A `Vector` that specifies the force to apply in the current step. It is zeroed after every `Body.update`. See also `Body.applyForce`.
 *
 * @property force
 * @type vector
 * @default { x: 0, y: 0 }
 ]]--

--[[
 * A `Number` that specifies the torque (turning force) to apply in the current step. It is zeroed after every `Body.update`.
 *
 * @property torque
 * @type number
 * @default 0
 ]]--

--[[
 * A `Number` that _measures_ the current speed of the body after the last `Body.update`. It is read-only and always positive (it's the magnitude of `body.velocity`).
 *
 * @readOnly
 * @property speed
 * @type number
 * @default 0
 ]]--

--[[
 * A `Number` that _measures_ the current angular speed of the body after the last `Body.update`. It is read-only and always positive (it's the magnitude of `body.angularVelocity`).
 *
 * @readOnly
 * @property angularSpeed
 * @type number
 * @default 0
 ]]--

--[[
 * A `Vector` that _measures_ the current velocity of the body after the last `Body.update`. It is read-only.
 * If you need to modify a body's velocity directly, you should either apply a force or simply change the body's `position` (as the engine uses position-Verlet integration).
 *
 * @readOnly
 * @property velocity
 * @type vector
 * @default { x: 0, y: 0 }
 ]]--

--[[
 * A `Number` that _measures_ the current angular velocity of the body after the last `Body.update`. It is read-only.
 * If you need to modify a body's angular velocity directly, you should apply a torque or simply change the body's `angle` (as the engine uses position-Verlet integration).
 *
 * @readOnly
 * @property angularVelocity
 * @type number
 * @default 0
 ]]--

--[[
 * A flag that indicates whether a body is considered static. A static body can never change position or angle and is completely fixed.
 * If you need to set a body as static after its creation, you should use `Body.setStatic` as this requires more than just setting this flag.
 *
 * @property isStatic
 * @type boolean
 * @default false
 ]]--

--[[
 * A flag that indicates whether a body is a sensor. Sensor triggers collision events, but doesn't react with colliding body physically.
 *
 * @property isSensor
 * @type boolean
 * @default false
 ]]--

--[[
 * A flag that indicates whether the body is considered sleeping. A sleeping body acts similar to a static body, except it is only temporary and can be awoken.
 * If you need to set a body as sleeping, you should use `Sleeping.set` as this requires more than just setting this flag.
 *
 * @property isSleeping
 * @type boolean
 * @default false
 ]]--

--[[
 * A `Number` that _measures_ the amount of movement a body currently has (a combination of `speed` and `angularSpeed`). It is read-only and always positive.
 * It is used and updated by the `Matter.Sleeping` module during simulation to decide if a body has come to rest.
 *
 * @readOnly
 * @property motion
 * @type number
 * @default 0
 ]]--

--[[
 * A `Number` that defines the number of updates in which this body must have near-zero velocity before it is set as sleeping by the `Matter.Sleeping` module (if sleeping is enabled by the engine).
 *
 * @property sleepThreshold
 * @type number
 * @default 60
 ]]--

--[[
 * A `Number` that defines the density of the body, that is its mass per unit area.
 * If you pass the density via `Body.create` the `mass` property is automatically calculated for you based on the size (area) of the object.
 * This is generally preferable to simply setting mass and allows for more intuitive definition of materials (e.g. rock has a higher density than wood).
 *
 * @property density
 * @type number
 * @default 0.001
 ]]--

--[[
 * A `Number` that defines the mass of the body, although it may be more appropriate to specify the `density` property instead.
 * If you modify this value, you must also modify the `body.inverseMass` property (`1 / mass`).
 *
 * @property mass
 * @type number
 ]]--

--[[
 * A `Number` that defines the inverse mass of the body (`1 / mass`).
 * If you modify this value, you must also modify the `body.mass` property.
 *
 * @property inverseMass
 * @type number
 ]]--

--[[
 * A `Number` that defines the moment of inertia (i.e. second moment of area) of the body.
 * It is automatically calculated from the given convex hull (`vertices` array) and density in `Body.create`.
 * If you modify this value, you must also modify the `body.inverseInertia` property (`1 / inertia`).
 *
 * @property inertia
 * @type number
 ]]--

--[[
 * A `Number` that defines the inverse moment of inertia of the body (`1 / inertia`).
 * If you modify this value, you must also modify the `body.inertia` property.
 *
 * @property inverseInertia
 * @type number
 ]]--

--[[
 * A `Number` that defines the restitution (elasticity) of the body. The value is always positive and is in the range `(0, 1)`.
 * A value of `0` means collisions may be perfectly inelastic and no bouncing may occur.
 * A value of `0.8` means the body may bounce back with approximately 80% of its kinetic energy.
 * Note that collision response is based on _pairs_ of bodies, and that `restitution` values are _combined_ with the following formula:
 *
 *	 Math.max(bodyA.restitution, bodyB.restitution)
 *
 * @property restitution
 * @type number
 * @default 0
 ]]--

--[[
 * A `Number` that defines the friction of the body. The value is always positive and is in the range `(0, 1)`.
 * A value of `0` means that the body may slide indefinitely.
 * A value of `1` means the body may come to a stop almost instantly after a force is applied.
 *
 * The effects of the value may be non-linear.
 * High values may be unstable depending on the body.
 * The engine uses a Coulomb friction model including static and kinetic friction.
 * Note that collision response is based on _pairs_ of bodies, and that `friction` values are _combined_ with the following formula:
 *
 *	 Math.min(bodyA.friction, bodyB.friction)
 *
 * @property friction
 * @type number
 * @default 0.1
 ]]--

--[[
 * A `Number` that defines the static friction of the body (in the Coulomb friction model).
 * A value of `0` means the body will never 'stick' when it is nearly stationary and only dynamic `friction` is used.
 * The higher the value (e.g. `10`), the more force it will take to initially get the body moving when nearly stationary.
 * This value is multiplied with the `friction` property to make it easier to change `friction` and maintain an appropriate amount of static friction.
 *
 * @property frictionStatic
 * @type number
 * @default 0.5
 ]]--

--[[
 * A `Number` that defines the air friction of the body (air resistance).
 * A value of `0` means the body will never slow as it moves through space.
 * The higher the value, the faster a body slows when moving through space.
 * The effects of the value are non-linear.
 *
 * @property frictionAir
 * @type number
 * @default 0.01
 ]]--

--[[
 * An `Object` that specifies the collision filtering properties of this body.
 *
 * Collisions between two bodies will obey the following rules:
 * - If the two bodies have the same non-zero value of `collisionFilter.group`,
 *   they will always collide if the value is positive, and they will never collide
 *   if the value is negative.
 * - If the two bodies have different values of `collisionFilter.group` or if one
 *   (or both) of the bodies has a value of 0, then the category/mask rules apply as follows:
 *
 * Each body belongs to a collision category, given by `collisionFilter.category`. This
 * value is used as a bit field and the category should have only one bit set, meaning that
 * the value of this property is a power of two in the range [1, 2^31]. Thus, there are 32
 * different collision categories available.
 *
 * Each body also defines a collision bitmask, given by `collisionFilter.mask` which specifies
 * the categories it collides with (the value is the bitwise AND value of all these categories).
 *
 * Using the category/mask rules, two bodies `A` and `B` collide if each includes the other's
 * category in its mask, i.e. `(categoryA & maskB) ~= 0` and `(categoryB & maskA) ~= 0`
 * are both true.
 *
 * @property collisionFilter
 * @type object
 ]]--

--[[
 * An Integer `Number`, that specifies the collision group this body belongs to.
 * See `body.collisionFilter` for more information.
 *
 * @property collisionFilter.group
 * @type object
 * @default 0
 ]]--

--[[
 * A bit field that specifies the collision category this body belongs to.
 * The category value should have only one bit set, for example `0x0001`.
 * This means there are up to 32 unique collision categories available.
 * See `body.collisionFilter` for more information.
 *
 * @property collisionFilter.category
 * @type object
 * @default 1
 ]]--

--[[
 * A bit mask that specifies the collision categories this body may collide with.
 * See `body.collisionFilter` for more information.
 *
 * @property collisionFilter.mask
 * @type object
 * @default -1
 ]]--

--[[
 * A `Number` that specifies a tolerance on how far a body is allowed to 'sink' or rotate into other bodies.
 * Avoid changing this value unless you understand the purpose of `slop` in physics engines.
 * The default should generally suffice, although very large bodies may require larger values for stable stacking.
 *
 * @property slop
 * @type number
 * @default 0.05
 ]]--

--[[
 * A `Number` that allows per-body time scaling, e.g. a force-field where bodies inside are in slow-motion, while others are at full speed.
 *
 * @property timeScale
 * @type number
 * @default 1
 ]]--

--[[
 * An `Object` that defines the rendering properties to be consumed by the module `Matter.Render`.
 *
 * @property render
 * @type object
 ]]--

--[[
 * A flag that indicates if the body should be rendered.
 *
 * @property render.visible
 * @type boolean
 * @default true
 ]]--

--[[
 * Sets the opacity to use when rendering.
 *
 * @property render.opacity
 * @type number
 * @default 1
]]--

--[[
 * An `Object` that defines the sprite properties to use when rendering, if any.
 *
 * @property render.sprite
 * @type object
 ]]--

--[[
 * An `String` that defines the path to the image to use as the sprite texture, if any.
 *
 * @property render.sprite.texture
 * @type string
 ]]--

--[[
 * A `Number` that defines the scaling in the x-axis for the sprite, if any.
 *
 * @property render.sprite.xScale
 * @type number
 * @default 1
 ]]--

--[[
 * A `Number` that defines the scaling in the y-axis for the sprite, if any.
 *
 * @property render.sprite.yScale
 * @type number
 * @default 1
 ]]--

--[[
  * A `Number` that defines the offset in the x-axis for the sprite (normalised by texture width).
  *
  * @property render.sprite.xOffset
  * @type number
  * @default 0
  ]]--

--[[
  * A `Number` that defines the offset in the y-axis for the sprite (normalised by texture height).
  *
  * @property render.sprite.yOffset
  * @type number
  * @default 0
  ]]--

--[[
 * A `Number` that defines the line width to use when rendering the body outline (if a sprite is not defined).
 * A value of `0` means no outline will be rendered.
 *
 * @property render.lineWidth
 * @type number
 * @default 0
 ]]--

--[[
 * A `String` that defines the fill style to use when rendering the body (if a sprite is not defined).
 * It is the same as when using a canvas, so it accepts CSS style property values.
 *
 * @property render.fillStyle
 * @type string
 * @default a random colour
 ]]--

--[[
 * A `String` that defines the stroke style to use when rendering the body outline (if a sprite is not defined).
 * It is the same as when using a canvas, so it accepts CSS style property values.
 *
 * @property render.strokeStyle
 * @type string
 * @default a random colour
 ]]--

--[[
 * An array of unique axis vectors (edge normals) used for collision detection.
 * These are automatically calculated from the given convex hull (`vertices` array) in `Body.create`.
 * They are constantly updated by `Body.update` during the simulation.
 *
 * @property axes
 * @type vector[]
 ]]--

--[[
 * A `Number` that _measures_ the area of the body's convex hull, calculated at creation by `Body.create`.
 *
 * @property area
 * @type string
 * @default
 ]]--

--[[
 * A `Bounds` object that defines the AABB region for the body.
 * It is automatically calculated from the given convex hull (`vertices` array) in `Body.create` and constantly updated by `Body.update` during simulation.
 *
 * @property bounds
 * @type bounds
 ]]--
