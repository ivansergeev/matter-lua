--[[
* The `Matter.Constraint` module contains methods for creating and manipulating constraints.
* Constraints are used for specifying that a fixed distance must be maintained between two bodies (or a body and a fixed world-space position).
* The stiffness of constraints can be modified to create springs or elastic.
*
* See the included usage [examples](https://github.com/liabru/matter-js/tree/master/examples).
*
* @class Constraint
]]--

import 'matter/geometry/Vertices'
import 'matter/geometry/Vector'
import 'matter/core/Sleeping'
import 'matter/geometry/Bounds'
import 'matter/geometry/Axes'
import 'matter/core/Common'

Constraint = {}
Constraint.__index = Constraint
Constraint._warming = 0.4
Constraint._torqueDampen = 1
Constraint._minLength = 0.000001

--[[
 * Creates a new constraint.
 * All properties have default values, and many are pre-calculated automatically based on other properties.
 * To simulate a revolute constraint (or pin joint) set `length: 0` and a high `stiffness` value (e.g. `0.7` or above).
 * If the constraint is unstable, try lowering the `stiffness` value and / or increasing `engine.constraintIterations`.
 * For compound bodies, constraints must be applied to the parent body (not one of its parts).
 * See the properties section below for detailed information on what you can pass via the `options` object.
 * @method create
 * @param {} options
 * @return {constraint} constraint
 ]]--

function Constraint.create(options)

	-- print('Constraint.create')

	local constraint = options

	-- if bodies defined but no points, use body centre
	if (constraint.bodyA and not constraint.pointA) then
		constraint.pointA = { x = 0, y = 0 }
	end

	if (constraint.bodyB and not constraint.pointB) then
		constraint.pointB = { x = 0, y = 0 }
	end

	-- calculate static length using initial world space points
	local initialPointA = constraint.bodyA and Vector.add(constraint.bodyA.position, constraint.pointA) or constraint.pointA
	local initialPointB = constraint.bodyB and Vector.add(constraint.bodyB.position, constraint.pointB) or constraint.pointB
	local length = Vector.magnitude(Vector.sub(initialPointA, initialPointB))


	constraint.length = type(constraint.length) ~= 'nil' and constraint.length or length

	-- option defaults
	constraint.id = constraint.id or Common.nextId()
	constraint.label = constraint.label or 'Constraint'
	constraint.type = 'constraint'
	constraint.stiffness = constraint.stiffness or (#constraint > 0 and 1 or 0.7)
	constraint.damping = constraint.damping or 0
	constraint.angularStiffness = constraint.angularStiffness or 0
	constraint.angleA = constraint.bodyA and constraint.bodyA.angle or constraint.angleA
	constraint.angleB = constraint.bodyB and constraint.bodyB.angle or constraint.angleB
	constraint.plugin = {}

	-- render
	local render = {
		visible = true,
		lineWidth = 2,
		strokeStyle = '#ffffff',
		type = 'line',
		anchors = true
	}

	if (constraint.length == 0 and constraint.stiffness > 0.1) then
		render.type = 'pin'
		render.anchors = false
	elseif (constraint.stiffness < 0.9) then
		render.type = 'spring'
	end

	constraint.render = Common.extend(render, constraint.render)

	return constraint
end

--[[
 * Prepares for solving by constraint warming.
 * @private
 * @method preSolveAll
 * @param {body[]} bodies
 ]]--

function Constraint.preSolveAll(bodies)

	-- print('Constraint.preSolveAll')

	local n = #bodies

	for i = 1, n do
		repeat
			local body = bodies[i]
			local impulse = body.constraintImpulse

			if (body.isStatic or (impulse.x == 0 and impulse.y == 0 and impulse.angle == 0)) then
				break
			end

			body.position.x += impulse.x
			body.position.y += impulse.y
			body.angle += impulse.angle

		break
		until true
	end
end

--[[
 * Solves all constraints in a list of collisions.
 * @private
 * @method solveAll
 * @param {constraint[]} constraints
 * @param {number} timeScale
 ]]--

function Constraint.solveAll(constraints, timeScale)

	local n = #constraints
	-- Solve fixed constraints first.
	for i = 1, n do
		local constraint = constraints[i]
		local fixedA =  not constraint.bodyA or (constraint.bodyA and constraint.bodyA.isStatic)
		local fixedB = not constraint.bodyB or (constraint.bodyB and constraint.bodyB.isStatic)

		if (fixedA or fixedB) then
			Constraint.solve(constraints[i], timeScale)
		end
	end

	-- Solve free constraints last.
	for i = 1, n do
		constraint = constraints[i]
		fixedA = not constraint.bodyA or (constraint.bodyA and constraint.bodyA.isStatic)
		fixedB = not constraint.bodyB or (constraint.bodyB and constraint.bodyB.isStatic)

		if (not fixedA and not fixedB) then
			Constraint.solve(constraints[i], timeScale)
		end
	end
end

--[[
 * Solves a distance constraint with Gauss-Siedel method.
 * @private
 * @method solve
 * @param {constraint} constraint
 * @param {number} timeScale
 ]]--

function Constraint.solve(constraint, timeScale)
	local bodyA = constraint.bodyA
	local bodyB = constraint.bodyB
	local pointA = constraint.pointA
	local pointB = constraint.pointB

	if (not bodyA and not bodyB) then
		return nil
	end

	-- update reference angle
	if (bodyA and not bodyA.isStatic) then
		Vector.rotate(pointA, bodyA.angle - constraint.angleA, pointA)
		constraint.angleA = bodyA.angle
	end

	-- update reference angle
	if (bodyB and not bodyB.isStatic) then
		Vector.rotate(pointB, bodyB.angle - constraint.angleB, pointB)
		constraint.angleB = bodyB.angle
	end

	local pointAWorld = pointA
	local pointBWorld = pointB

	if (bodyA)  then
		pointAWorld = Vector.add(bodyA.position, pointA)
	end

	if (bodyB) then
		pointBWorld = Vector.add(bodyB.position, pointB)
	end

	if (not pointAWorld or not pointBWorld) then
		return nil
	end

	local delta = Vector.sub(pointAWorld, pointBWorld)
	local currentLength = Vector.magnitude(delta)

	-- prevent singularity
	if (currentLength < Constraint._minLength) then
		currentLength = Constraint._minLength
	end

	-- solve distance constraint with Gauss-Siedel method
	local difference = (currentLength - constraint.length) / currentLength
	local stiffness = constraint.stiffness < 1 and constraint.stiffness * timeScale or constraint.stiffness
	local force = Vector.mult(delta, difference * stiffness)
	local massTotal = (bodyA and bodyA.inverseMass or 0) + (bodyB and bodyB.inverseMass or 0)
	local inertiaTotal = (bodyA and bodyA.inverseInertia or 0) + (bodyB and bodyB.inverseInertia or 0)
	local resistanceTotal = massTotal + inertiaTotal

	local	torque,
		share,
		normal,
		normalVelocity,
		relativeVelocity

	if (constraint.damping) then
		local zero = Vector.create()
		normal = Vector.div(delta, currentLength)

		relativeVelocity = Vector.sub(
			bodyB and Vector.sub(bodyB.position, bodyB.positionPrev) or zero,
			bodyA and Vector.sub(bodyA.position, bodyA.positionPrev) or zero
		)

		normalVelocity = Vector.dot(normal, relativeVelocity)
	end

	if (bodyA and not bodyA.isStatic) then
		share = bodyA.inverseMass / massTotal

		-- keep track of applied impulses for post solving
		bodyA.constraintImpulse.x -= force.x * share
		bodyA.constraintImpulse.y -= force.y * share

		-- apply forces
		bodyA.position.x -= force.x * share
		bodyA.position.y -= force.y * share

		-- apply damping
		if (constraint.damping) then
			bodyA.positionPrev.x -= constraint.damping * normal.x * normalVelocity * share
			bodyA.positionPrev.y -= constraint.damping * normal.y * normalVelocity * share
		end

		-- apply torque
		torque = (Vector.cross(pointA, force) / resistanceTotal) * Constraint._torqueDampen * bodyA.inverseInertia * (1 - constraint.angularStiffness)
		bodyA.constraintImpulse.angle -= torque
		bodyA.angle -= torque
	end

	if (bodyB and not bodyB.isStatic) then
		share = bodyB.inverseMass / massTotal

		-- keep track of applied impulses for post solving
		bodyB.constraintImpulse.x += force.x * share
		bodyB.constraintImpulse.y += force.y * share

		-- apply forces
		bodyB.position.x += force.x * share
		bodyB.position.y += force.y * share

		-- apply damping
		if (constraint.damping) then
			bodyB.positionPrev.x += constraint.damping * normal.x * normalVelocity * share
			bodyB.positionPrev.y += constraint.damping * normal.y * normalVelocity * share
		end

		-- apply torque
		torque = (Vector.cross(pointB, force) / resistanceTotal) * Constraint._torqueDampen * bodyB.inverseInertia * (1 - constraint.angularStiffness)
		bodyB.constraintImpulse.angle += torque
		bodyB.angle += torque
	end
end

--[[
 * Performs body updates required after solving constraints.
 * @private
 * @method postSolveAll
 * @param {body[]} bodies
 ]]--
function Constraint.postSolveAll(bodies)
	local n = #bodies
	for i = 1, n do
		repeat
			local body = bodies[i]
			local impulse = body.constraintImpulse

			if (body.isStatic or (impulse.x == 0 and impulse.y == 0 and impulse.angle == 0)) then
				break
			end

			Sleeping.set(body, false)

			-- update geometry and reset
			local p = #body.parts

			for j = 1, p do
				local part = body.parts[j]

				Vertices.translate(part.vertices, impulse)

				if (j > 1) then
					part.position.x += impulse.x
					part.position.y += impulse.y
				end

				if (impulse.angle ~= 0) then
					Vertices.rotate(part.vertices, impulse.angle, body.position)
					Axes.rotate(part.axes, impulse.angle)
					if (j > 1) then
						Vector.rotateAbout(part.position, impulse.angle, body.position, part.position)
					end
				end

				Bounds.update(part.bounds, part.vertices, body.velocity)
			end

			-- dampen the cached impulse for warming next step
			impulse.angle *= Constraint._warming
			impulse.x *= Constraint._warming
			impulse.y *= Constraint._warming
		break
		until true
	end
end

--[[
 * Returns the world-space position of `constraint.pointA`, accounting for `constraint.bodyA`.
 * @method pointAWorld
 * @param {constraint} constraint
 * @returns {vector} the world-space position
 ]]--

function Constraint.pointAWorld(constraint)
	return {
		x = (constraint.bodyA and constraint.bodyA.position.x or 0) + constraint.pointA.x,
		y = (constraint.bodyA and constraint.bodyA.position.y or 0) + constraint.pointA.y
	}
end

--[[
 * Returns the world-space position of `constraint.pointB`, accounting for `constraint.bodyB`.
 * @method pointBWorld
 * @param {constraint} constraint
 * @returns {vector} the world-space position
 ]]--

function Constraint.pointBWorld(constraint)
	return {
		x = (constraint.bodyB and constraint.bodyB.position.x or 0) + constraint.pointB.x,
		y = (constraint.bodyB and constraint.bodyB.position.y or 0) + constraint.pointB.y
	}
end

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
 * @default "constraint"
 * @readOnly
 ]]--

--[[
 * An arbitrary `String` name to help the user identify and manage bodies.
 *
 * @property label
 * @type string
 * @default "Constraint"
 ]]--

--[[
 * An `Object` that defines the rendering properties to be consumed by the module `Matter.Render`.
 *
 * @property render
 * @type object
 ]]--

--[[
 * A flag that indicates if the constraint should be rendered.
 *
 * @property render.visible
 * @type boolean
 * @default true
 ]]--

--[[
 * A `Number` that defines the line width to use when rendering the constraint outline.
 * A value of `0` means no outline will be rendered.
 *
 * @property render.lineWidth
 * @type number
 * @default 2
 ]]--

--[[
 * A `String` that defines the stroke style to use when rendering the constraint outline.
 * It is the same as when using a canvas, so it accepts CSS style property values.
 *
 * @property render.strokeStyle
 * @type string
 * @default a random colour
 ]]--

--[[
 * A `String` that defines the constraint rendering type.
 * The possible values are 'line', 'pin', 'spring'.
 * An appropriate render type will be automatically chosen unless one is given in options.
 *
 * @property render.type
 * @type string
 * @default 'line'
 ]]--

--[[
 * A `Boolean` that defines if the constraint's anchor points should be rendered.
 *
 * @property render.anchors
 * @type boolean
 * @default true
 ]]--

--[[
 * The first possible `Body` that this constraint is attached to.
 *
 * @property bodyA
 * @type body
 * @default null
 ]]--

--[[
 * The second possible `Body` that this constraint is attached to.
 *
 * @property bodyB
 * @type body
 * @default null
 ]]--

--[[
 * A `Vector` that specifies the offset of the constraint from center of the `constraint.bodyA` if defined, otherwise a world-space position.
 *
 * @property pointA
 * @type vector
 * @default { x: 0, y: 0 }
 ]]--

--[[
 * A `Vector` that specifies the offset of the constraint from center of the `constraint.bodyB` if defined, otherwise a world-space position.
 *
 * @property pointB
 * @type vector
 * @default { x: 0, y: 0 }
 ]]--

--[[
 * A `Number` that specifies the stiffness of the constraint, i.e. the rate at which it returns to its resting `constraint.length`.
 * A value of `1` means the constraint should be very stiff.
 * A value of `0.2` means the constraint acts like a soft spring.
 *
 * @property stiffness
 * @type number
 * @default 1
 ]]--

--[[
 * A `Number` that specifies the damping of the constraint,
 * i.e. the amount of resistance applied to each body based on their velocities to limit the amount of oscillation.
 * Damping will only be apparent when the constraint also has a very low `stiffness`.
 * A value of `0.1` means the constraint will apply heavy damping, resulting in little to no oscillation.
 * A value of `0` means the constraint will apply no damping.
 *
 * @property damping
 * @type number
 * @default 0
 ]]--

--[[
 * A `Number` that specifies the target resting length of the constraint.
 * It is calculated automatically in `Constraint.create` from initial positions of the `constraint.bodyA` and `constraint.bodyB`.
 *
 * @property length
 * @type number
 ]]--

--[[
 * An object reserved for storing plugin-specific properties.
 *
 * @property plugin
 * @type {}
 ]]--
