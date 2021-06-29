--[[
* The `Matter.Resolver` module contains methods for resolving collision pairs.
*
* @class Resolver
]]--

import 'matter/core/Common'
import 'matter/geometry/Vertices'
import 'matter/geometry/Vector'
import 'matter/geometry/Bounds'

Resolver = {}
Resolver.__index = Resolver

Resolver._restingThresh = 4
Resolver._restingThreshTangent = 6
Resolver._positionDampen = 0.9
Resolver._positionWarming = 0.8
Resolver._frictionNormalMultiplier = 5

--[[
* Prepare pairs for position solving.
* @method preSolvePosition
* @param {pair[]} pairs
]]--

function Resolver.preSolvePosition(pairs)

	-- print('Resolver.preSolvePosition', #pairs)

	local pair

	 -- find total contacts on each body

	for i = 1, #pairs do
		pair = pairs[i]

		if pair.isActive then

			pair.collision.parentA.totalContacts += #pair.activeContacts
			pair.collision.parentB.totalContacts += #pair.activeContacts
		end
	end
end

--[[
	* Find a solution for pair positions.
	* @method solvePosition
	* @param {pair[]} pairs
	* @param {number} timeScale
]]--

function Resolver.solvePosition(pairs, timeScale)

	-- print('Resolver.solvePosition', #pairs, timeScale)

	local pair,
		collision,
		bodyA,
		bodyB,
		normal,
		bodyBtoAX, bodyBtoAY,
		contactShare,
		positionImpulse,
		contactCount = {}

	local bx, by,
		sx, sy,
		ax, ay

	local tempA = Vector._temp[1]
	local tempB = Vector._temp[2]
	local tempC = Vector._temp[3]
	local tempD = Vector._temp[4]
	local n = #pairs

	-- find impulses required to resolve penetration
	for i = 1, n do
		repeat
			pair = pairs[i]

			if (not pair.isActive or pair.isSensor) then
				break
			end

			collision = pair.collision
			bodyA = collision.parentA
			bodyB = collision.parentB
			normal = collision.normal

			 -- get current separation between body edges involved in collision

			bx, by = vectorAdd(bodyB.positionImpulse.x, bodyB.positionImpulse.y, bodyB.position.x, bodyB.position.y, tempA)
			sx, sy = vectorSub(bodyB.position.x, bodyB.position.y, collision.penetration.x,  collision.penetration.y, tempB)
			ax, ay = vectorAdd(bodyA.positionImpulse.x, bodyA.positionImpulse.y, sx, sy, tempC)
			bodyBtoAX, bodyBtoAY = vectorSub(bx, by, ax, ay, tempD)

			pair.separation = vectorDot(normal.x, normal.y, bodyBtoAX, bodyBtoAY)

		break
		until true
	end

	for i = 1, n do
		repeat
			pair = pairs[i]

			if (not pair.isActive or pair.isSensor) then
				break
			end

			collision = pair.collision
			bodyA = collision.parentA
			bodyB = collision.parentB
			normal = collision.normal
			positionImpulse = (pair.separation - pair.slop) * timeScale

			if (bodyA.isStatic or bodyB.isStatic) then
				positionImpulse *= 2
			end

			if (not (bodyA.isStatic or bodyA.isSleeping)) then
				contactShare = Resolver._positionDampen / bodyA.totalContacts

				if 	bodyA.totalContacts > 0 then
					bodyA.positionImpulse.x += normal.x * positionImpulse * contactShare
					bodyA.positionImpulse.y += normal.y * positionImpulse * contactShare
				end
			end

			if ( not (bodyB.isStatic or bodyB.isSleeping)) then
				contactShare = Resolver._positionDampen / bodyB.totalContacts
				bodyB.positionImpulse.x -= normal.x * positionImpulse * contactShare
				bodyB.positionImpulse.y -= normal.y * positionImpulse * contactShare
			end
		break
		until true
	end
end

--[[
* Apply position resolution.
* @method postSolvePosition
* @param {body[]} bodies
]]--

function Resolver.postSolvePosition(bodies)

	-- print('Resolver.postSolvePosition', #bodies)

	local n = #bodies

	for i = 1, n do
		local body = bodies[i]

		-- reset contact count
		body.totalContacts = 0

		if (body.positionImpulse.x ~= 0 or body.positionImpulse.y ~= 0) then

			-- update body geometry
			local p = #body.parts
			for j = 1, p do

				local part = body.parts[j]
				Vertices.translate(part.vertices, body.positionImpulse)
				Bounds.update(part.bounds, part.vertices, body.velocity)
				part.position.x += body.positionImpulse.x
				part.position.y += body.positionImpulse.y
			end

			-- move the body without changing velocity
			body.positionPrev.x += body.positionImpulse.x
			body.positionPrev.y += body.positionImpulse.y

			if (vectorDot(body.positionImpulse.x, body.positionImpulse.y, body.velocity.x, body.velocity.y) < 0) then
				-- reset cached impulse if the body has velocity along it
				body.positionImpulse.x = 0
				body.positionImpulse.y = 0
			else
				-- warm the next iteration
				body.positionImpulse.x *= Resolver._positionWarming
				body.positionImpulse.y *= Resolver._positionWarming
			end
		end
	end
end

--[[
* Prepare pairs for velocity solving.
* @method preSolveVelocity
* @param {pair[]} pairs
]]--

function Resolver.preSolveVelocity(pairs)

	-- print('Resolver.preSolveVelocity', #pairs)

	local n = #pairs

	if n == 0 then
		return
	end

	local impulse = Vector._temp[1]
	local tempA = Vector._temp[2]

	local pair,
		contacts,
		collision,
		bodyA,
		bodyB,
		normal,
		tangent,
		contact,
		contactVertex,
		normalImpulse,
		tangentImpulse,
		offsetX, offsetY

	for i = 1, n do
		repeat
			pair = pairs[i]

			if (not pair.isActive or pair.isSensor) then
				break
			end

			contacts = pair.activeContacts
			collision = pair.collision
			bodyA = collision.parentA
			bodyB = collision.parentB
			normal = collision.normal
			tangent = collision.tangent

			-- resolve each contact
			local c = #contacts

			for j = 1, c do
				contact = contacts[j]
				contactVertex = contact.vertex
				normalImpulse = contact.normalImpulse
				tangentImpulse = contact.tangentImpulse

				if (normalImpulse ~= 0 or tangentImpulse ~= 0) then
					 -- total impulse from contact
					impulse.x = (normal.x * normalImpulse) + (tangent.x * tangentImpulse)
					impulse.y = (normal.y * normalImpulse) + (tangent.y * tangentImpulse)

					 -- apply impulse from contact
					if (not (bodyA.isStatic or bodyA.isSleeping)) then
						offsetX, offsetY = vectorSub(contactVertex.x, contactVertex.y, bodyA.position.x, bodyA.position.y, tempA)
						bodyA.positionPrev.x += impulse.x * bodyA.inverseMass
						bodyA.positionPrev.y += impulse.y * bodyA.inverseMass
						bodyA.anglePrev += vectorCross(offsetX, offsetY, impulse.x, impulse.y) * bodyA.inverseInertia
					end

					if (not(bodyB.isStatic or bodyB.isSleeping)) then
						offsetX, offsetY = vectorSub(contactVertex.x, contactVertex.y, bodyB.position.x, bodyB.position.y, tempA)
						bodyB.positionPrev.x -= impulse.x * bodyB.inverseMass
						bodyB.positionPrev.y -= impulse.y * bodyB.inverseMass
						bodyB.anglePrev -= vectorCross(offsetX, offsetY, impulse.x, impulse.y) * bodyB.inverseInertia
					end
				end
			end
		break
		until true
	end
end

--[[
* Find a solution for pair velocities.
* @method solveVelocity
* @param {pair[]} pairs
* @param {number} timeScale
]]--



function Resolver.solveVelocity(pairs, timeScale)

	-- print('Resolver.solveVelocity', #pairs, timeScale)

	local n = #pairs

	if n == 0 then
		return
	end

	local timeScaleSquared = timeScale * timeScale
	local impulse = Vector._temp[1]
	local tempA = Vector._temp[2]
	local tempB = Vector._temp[3]
	local tempC = Vector._temp[4]
	local tempD = Vector._temp[5]
	local tempE = Vector._temp[6]

	local pair = {}
	local collision	= {}
	local bodyA	= {}
	local bodyB	= {}
	local normalX = 0
	local normalY = 0
	local tangentX = 0
	local tangentY	= 0
	local contacts	= {}
	local c	= 0
	local contact	= {}
	local contactVertexX = 0
	local contactVertexY = 0
	local offsetAX = 0
	local offsetAY = 0
	local offsetBX, offsetBY
	local velocityPointAX = 0
	local velocityPointAY = 0
	local velocityPointBX = 0
	local velocityPointBY = 0
	local relativeVelocityX = 0
	local relativeVelocityY = 0
	local normalVelocity	= 0
	local tangentVelocity	= 0
	local tangentSpeed	= 0
	local tangentVelocityDirection	= 0
	local normalImpulse	= 0
	local normalForce 	= 0
	local tangentImpulse	= 0
	local maxFriction	= 0
	local oAcN	= 0
	local oBcN	= 0
	local share	= 0
	local contactNormalImpulse	= 0
	local contactTangentImpulse	= 0
	local mx, my, px, py

	for i = 1, n do
		repeat
			pair = pairs[i]

			if (not pair.isActive or pair.isSensor) then
				break
			end

			collision = pair.collision
			bodyA = collision.parentA
			bodyB = collision.parentB
			normalX, normalY = collision.normal.x, collision.normal.y
			tangentX, tangentY = collision.tangent.x, collision.tangent.y
			contacts = pair.activeContacts
			c = #contacts
			-- contactShare = 1 / c

			-- update body velocities
			bodyA.velocity.x = bodyA.position.x - bodyA.positionPrev.x
			bodyA.velocity.y = bodyA.position.y - bodyA.positionPrev.y
			bodyB.velocity.x = bodyB.position.x - bodyB.positionPrev.x
			bodyB.velocity.y = bodyB.position.y - bodyB.positionPrev.y
			bodyA.angularVelocity = bodyA.angle - bodyA.anglePrev
			bodyB.angularVelocity = bodyB.angle - bodyB.anglePrev

			-- resolve each contact
			for j = 1, c do

				contact = contacts[j]

				contactVertexX, contactVertexY = contact.vertex.x, contact.vertex.y
				-- offsetA
				offsetAX, offsetAY = vectorSub(contactVertexX, contactVertexY, bodyA.position.x, bodyA.position.y, tempA)
				-- offsetB
				offsetBX, offsetBY = vectorSub(contactVertexX, contactVertexY, bodyB.position.x, bodyB.position.y, tempB)

				px, py = vectorPerp(offsetAX, offsetAY)
				mx, my = vectorMult(px, py, bodyA.angularVelocity)
				velocityPointAX, velocityPointAY = vectorAdd(bodyA.velocity.x, bodyA.velocity.y, mx, my, tempC)

				px, py  = vectorPerp(offsetBX, offsetBY)
				mx, my = vectorMult(px, py, bodyB.angularVelocity)
				velocityPointBX, velocityPointBY = vectorAdd(bodyB.velocity.x, bodyB.velocity.y, mx, my, tempD)

				-- relativeVelocity
				relativeVelocityX, relativeVelocityY = vectorSub(velocityPointAX, velocityPointAY, velocityPointBX, velocityPointBY, tempE)
				normalVelocity = vectorDot(normalX, normalY, relativeVelocityX, relativeVelocityY)
				tangentVelocity = vectorDot(tangentX, tangentY, relativeVelocityX, relativeVelocityY)
				tangentSpeed = math.abs(tangentVelocity)
				tangentVelocityDirection = Common.sign(tangentVelocity)

				-- raw impulses
				normalImpulse = (1 + pair.restitution) * normalVelocity
				normalForce = Common.clamp(pair.separation + normalVelocity, 0, 1) * Resolver._frictionNormalMultiplier

				-- coulomb friction
				tangentImpulse = tangentVelocity
				maxFriction = math.huge

				if (tangentSpeed > pair.friction * pair.frictionStatic * normalForce * timeScaleSquared) then
					maxFriction = tangentSpeed
					tangentImpulse = Common.clamp(
						pair.friction * tangentVelocityDirection * timeScaleSquared,
						-maxFriction, maxFriction
					)
				end

				-- modify impulses accounting for mass, inertia and offset

				oAcN = vectorCross(offsetAX, offsetAY, normalX, normalY)
				oBcN = vectorCross(offsetBX, offsetBY, normalX, normalY)
				share = (1 / c) / (bodyA.inverseMass + bodyB.inverseMass + bodyA.inverseInertia * oAcN * oAcN  + bodyB.inverseInertia * oBcN * oBcN)

				normalImpulse *= share
				tangentImpulse *= share

				-- handle high velocity and resting collisions separately
				if (normalVelocity < 0 and normalVelocity * normalVelocity > Resolver._restingThresh * timeScaleSquared) then
					 -- high normal velocity so clear cached contact normal impulse
					contact.normalImpulse = 0
				else
					 -- solve resting collision constraints using Erin Catto's method (GDC08)
					-- impulse constraint tends to 0
					contactNormalImpulse = contact.normalImpulse
					contact.normalImpulse = math.min(contact.normalImpulse + normalImpulse, 0)
					normalImpulse = contact.normalImpulse - contactNormalImpulse
				end

				 -- handle high velocity and resting collisions separately
				if (tangentVelocity * tangentVelocity > Resolver._restingThreshTangent * timeScaleSquared) then
					 -- high tangent velocity so clear cached contact tangent impulse
					contact.tangentImpulse = 0
				else
					-- solve resting collision constraints using Erin Catto's method (GDC08)
					-- tangent impulse tends to -tangentSpeed or +tangentSpeed
					contactTangentImpulse = contact.tangentImpulse

					contact.tangentImpulse = Common.clamp(contact.tangentImpulse + tangentImpulse, -maxFriction, maxFriction)
					tangentImpulse = contact.tangentImpulse - contactTangentImpulse
				end

				-- total impulse from contact
				impulse.x = (normalX * normalImpulse) + (tangentX * tangentImpulse)
				impulse.y = (normalY * normalImpulse) + (tangentY * tangentImpulse)

				-- apply impulse from contact
				if (not (bodyA.isStatic or bodyA.isSleeping)) then

					bodyA.positionPrev.x += impulse.x * bodyA.inverseMass
					bodyA.positionPrev.y += impulse.y * bodyA.inverseMass


					bodyA.anglePrev += vectorCross(offsetAX, offsetAY, impulse.x, impulse.y) * bodyA.inverseInertia

				end

				if (not (bodyB.isStatic or bodyB.isSleeping)) then

					bodyB.positionPrev.x -= impulse.x * bodyB.inverseMass
					bodyB.positionPrev.y -= impulse.y * bodyB.inverseMass
					bodyB.anglePrev -= vectorCross(offsetBX, offsetBY, impulse.x, impulse.y) * bodyB.inverseInertia
				end
			end
		break
		until true
	end
end

function Resolver.solveVelocity__(pairs, timeScale)

	-- print('Resolver.solveVelocity', #pairs, timeScale)

	local n = #pairs

	if n == 0 then
		return
	end

	local timeScaleSquared = timeScale * timeScale
	local impulse = Vector._temp[1]
	local tempA = Vector._temp[2]
	local tempB = Vector._temp[3]
	local tempC = Vector._temp[4]
	local tempD = Vector._temp[5]
	local tempE = Vector._temp[6]

	for i = 1, n do
		repeat
			local pair = pairs[i]

			if (not pair.isActive or pair.isSensor) then
				break
			end

			local collision = pair.collision
			local bodyA = collision.parentA
			local bodyB = collision.parentB
			local normal = collision.normal
			local tangent = collision.tangent
			local contacts = pair.activeContacts
			local c = #contacts
			local contactShare = 1 / c

			 -- update body velocities
			bodyA.velocity.x = bodyA.position.x - bodyA.positionPrev.x
			bodyA.velocity.y = bodyA.position.y - bodyA.positionPrev.y
			bodyB.velocity.x = bodyB.position.x - bodyB.positionPrev.x
			bodyB.velocity.y = bodyB.position.y - bodyB.positionPrev.y
			bodyA.angularVelocity = bodyA.angle - bodyA.anglePrev
			bodyB.angularVelocity = bodyB.angle - bodyB.anglePrev

			-- resolve each contact
			for j = 1, c do
				local contact = contacts[j]
				local contactVertex = contact.vertex
				local offsetA = Vector.sub(contactVertex, bodyA.position, tempA)
				local offsetB = Vector.sub(contactVertex, bodyB.position, tempB)
				local velocityPointA = Vector.add(bodyA.velocity, Vector.mult(Vector.perp(offsetA), bodyA.angularVelocity), tempC)
				local velocityPointB = Vector.add(bodyB.velocity, Vector.mult(Vector.perp(offsetB), bodyB.angularVelocity), tempD)
				local relativeVelocity = Vector.sub(velocityPointA, velocityPointB, tempE)
				local normalVelocity = Vector.dot(normal, relativeVelocity)
				local tangentVelocity = Vector.dot(tangent, relativeVelocity)
				local tangentSpeed = math.abs(tangentVelocity)
				local tangentVelocityDirection = Common.sign(tangentVelocity)

				-- raw impulses
				local normalImpulse = (1 + pair.restitution) * normalVelocity
				local normalForce = Common.clamp(pair.separation + normalVelocity, 0, 1) * Resolver._frictionNormalMultiplier

				-- coulomb friction
				local tangentImpulse = tangentVelocity
				local maxFriction = math.huge

				if (tangentSpeed > pair.friction * pair.frictionStatic * normalForce * timeScaleSquared) then
					maxFriction = tangentSpeed
					tangentImpulse = Common.clamp(
						pair.friction * tangentVelocityDirection * timeScaleSquared,
						-maxFriction, maxFriction
					)
				end

				-- modify impulses accounting for mass, inertia and offset

				local oAcN = Vector.cross(offsetA, normal)
				local oBcN = Vector.cross(offsetB, normal)
				local share = contactShare / (bodyA.inverseMass + bodyB.inverseMass + bodyA.inverseInertia * oAcN * oAcN  + bodyB.inverseInertia * oBcN * oBcN)

				normalImpulse *= share
				tangentImpulse *= share

				-- handle high velocity and resting collisions separately
				if (normalVelocity < 0 and normalVelocity * normalVelocity > Resolver._restingThresh * timeScaleSquared) then
					 -- high normal velocity so clear cached contact normal impulse
					contact.normalImpulse = 0
				else
					 -- solve resting collision constraints using Erin Catto's method (GDC08)
					-- impulse constraint tends to 0
					local contactNormalImpulse = contact.normalImpulse
					contact.normalImpulse = math.min(contact.normalImpulse + normalImpulse, 0)
					normalImpulse = contact.normalImpulse - contactNormalImpulse
				end

				 -- handle high velocity and resting collisions separately
				if (tangentVelocity * tangentVelocity > Resolver._restingThreshTangent * timeScaleSquared) then
					 -- high tangent velocity so clear cached contact tangent impulse
					contact.tangentImpulse = 0
				else
					-- solve resting collision constraints using Erin Catto's method (GDC08)
					-- tangent impulse tends to -tangentSpeed or +tangentSpeed
					local contactTangentImpulse = contact.tangentImpulse
					contact.tangentImpulse = Common.clamp(contact.tangentImpulse + tangentImpulse, -maxFriction, maxFriction)
					tangentImpulse = contact.tangentImpulse - contactTangentImpulse
				end

				-- total impulse from contact
				impulse.x = (normal.x * normalImpulse) + (tangent.x * tangentImpulse)
				impulse.y = (normal.y * normalImpulse) + (tangent.y * tangentImpulse)

				-- apply impulse from contact
				if (not (bodyA.isStatic or bodyA.isSleeping)) then
					bodyA.positionPrev.x += impulse.x * bodyA.inverseMass
					bodyA.positionPrev.y += impulse.y * bodyA.inverseMass
					bodyA.anglePrev += Vector.cross(offsetA, impulse) * bodyA.inverseInertia
				end

				if (not (bodyB.isStatic or bodyB.isSleeping)) then
					bodyB.positionPrev.x -= impulse.x * bodyB.inverseMass
					bodyB.positionPrev.y -= impulse.y * bodyB.inverseMass
					bodyB.anglePrev -= Vector.cross(offsetB, impulse) * bodyB.inverseInertia
				end
			end
		break
		until true
	end
end


