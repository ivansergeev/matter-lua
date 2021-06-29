--[[
* The `Matter.SAT` module contains methods for detecting collisions using the Separating Axis Theorem.
*
* @class SAT
]]--

-- TODO: true circles and curves

import 'matter/geometry/Vertices'
import 'matter/geometry/Vector'

local SATOverlapAxes,
	SATFindSupports,
	SATProjectToAxis

SAT = {}
SAT.__index = SAT


--[[
 * Detect collision between two bodies using the Separating Axis Theorem.
 * @method collides
 * @param {body} bodyA
 * @param {body} bodyB
 * @param {collision} previousCollision
 * @return {collision} collision
 ]]--

function SAT.collides_SRC(bodyA, bodyB, previousCollision)


	local overlapAB,
		overlapBA,
		minOverlap,
		collision,
		canReusePrevCol = false

	if (previousCollision) then
		-- estimate total motion
		local parentA = bodyA.parent
		local	parentB = bodyB.parent
		local	motion = parentA.speed * parentA.speed + parentA.angularSpeed * parentA.angularSpeed
				   + parentB.speed * parentB.speed + parentB.angularSpeed * parentB.angularSpeed


	   -- we may be able to (partially) reuse collision result
		-- but only safe if collision was resting

		print('motion', 	motion)
		-- canReusePrevCol = previousCollision and previousCollision.collided and motion < 0.2
		canReusePrevCol = previousCollision and previousCollision.collided and motion < 3

	-- reuse collision object
		collision = previousCollision
	else
		collision = { collided = false, bodyA = bodyA, bodyB = bodyB }
	end

	if (previousCollision and canReusePrevCol) then
		-- if we can reuse the collision result
		-- we only need to test the previously found axis
		local axisBodyA = collision.axisBody
		local	axisBodyB = axisBodyA == bodyA and bodyB or bodyA
		 local   axes = {axisBodyA.axes[previousCollision.axisNumber]}

		minOverlap = SAT._overlapAxes(axisBodyA.vertices, axisBodyB.vertices, axes)
		collision.reused = true

		if (minOverlap.overlap <= 0) then
			collision.collided = false
			return collision
		end

	else
		-- if we can't reuse a result, perform a full SAT test

		overlapAB = SAT._overlapAxes(bodyA.vertices, bodyB.vertices, bodyA.axes)

		if (overlapAB.overlap <= 0) then
			collision.collided = false
			return collision
		end

		overlapBA = SAT._overlapAxes(bodyB.vertices, bodyA.vertices, bodyB.axes)

		if (overlapBA.overlap <= 0) then
			collision.collided = false
			return collision
		end

		if (overlapAB.overlap < overlapBA.overlap) then
			minOverlap = overlapAB
			collision.axisBody = bodyA
		else
			minOverlap = overlapBA
			collision.axisBody = bodyB
		end

		-- important for reuse later
		collision.axisNumber = minOverlap.axisNumber
	end

	collision.bodyA = bodyA.id < bodyB.id and bodyA or bodyB
	collision.bodyB = bodyA.id < bodyB.id and bodyB or bodyA
	collision.collided = true
	collision.depth = minOverlap.overlap
	collision.parentA = collision.bodyA.parent
	collision.parentB = collision.bodyB.parent

	bodyA = collision.bodyA
	bodyB = collision.bodyB

	-- ensure normal is facing away from bodyA

	if (Vector.dot(minOverlap.axis, Vector.sub(bodyB.position, bodyA.position)) < 0) then
		collision.normal = {
			x = minOverlap.axis.x,
			y = minOverlap.axis.y
		}
	else
		collision.normal = {
			x = -minOverlap.axis.x,
			y = -minOverlap.axis.y
		}
	end

	collision.tangent = Vector.perp(collision.normal)

	collision.penetration = collision.penetration or {}
	collision.penetration.x = collision.normal.x * collision.depth
	collision.penetration.y = collision.normal.y * collision.depth

	-- find support points, there is always either exactly one or two
	local verticesB = SAT._findSupports(bodyA, bodyB, collision.normal)
	local supports = {}

	-- find the supports from bodyB that are inside bodyA
	if (Vertices.contains(bodyA.vertices, verticesB[1])) then
	   table.insert(supports, verticesB[1])
	end

	if (Vertices.contains(bodyA.vertices, verticesB[2])) then
		table.insert(supports, verticesB[2])
	end

	-- find the supports from bodyA that are inside bodyB
	if (#supports < 2) then
		local verticesA = SAT._findSupports(bodyB, bodyA, Vector.neg(collision.normal))

		if (Vertices.contains(bodyB.vertices, verticesA[1])) then
			table.insert(supports, verticesA[1])
		end

		if (#supports < 2 and Vertices.contains(bodyB.vertices, verticesA[2])) then
			table.insert(supports, verticesA[2])
		end
	end

	-- account for the edge case of overlapping but no vertex containment
	if (#supports < 1) then
		supports = {verticesB[1]}
	end

	collision.supports = supports

	return collision
end

function SAT.collides(bodyA, bodyB, previousCollision)

	-- print('SAT.collides')

	local canReusePrevCol = false
	local VerticesContains = Vertices.contains
	local overlapAB,
		overlapBA,
		minOverlap,
		collision

	if (previousCollision) then
		-- estimate total motion
		local parentA = bodyA.parent
		local parentB = bodyB.parent
		local motion = parentA.speed * parentA.speed + parentA.angularSpeed * parentA.angularSpeed
				   + parentB.speed * parentB.speed + parentB.angularSpeed * parentB.angularSpeed

		-- we may be able to (partially) reuse collision result
		-- but only safe if collision was resting
		canReusePrevCol = previousCollision and previousCollision.collided and motion < 3
		-- default 0.2

		-- reuse collision object
		collision = previousCollision
	else
		collision = {
			collided = false,
			bodyA = bodyA,
			bodyB = bodyB,
		}
	end

	if (previousCollision and canReusePrevCol) then

		-- if we can reuse the collision result
		-- we only need to test the previously found axis
		local axisBodyA = collision.axisBody
		local axisBodyB = axisBodyA == bodyA and bodyB or bodyA
		local axes = {axisBodyA.axes[previousCollision.axisNumber]}

		minOverlap = SATOverlapAxes(axisBodyA.vertices, axisBodyB.vertices, axes)
		collision.reused = true

		if (minOverlap.overlap <= 0) then
			collision.collided = false
			return collision
		end

	else
		-- if we can't reuse a result, perform a full SAT test

		overlapAB = SATOverlapAxes(bodyA.vertices, bodyB.vertices, bodyA.axes)

		if (overlapAB.overlap <= 0) then
			collision.collided = false
			return collision
		end

		overlapBA = SATOverlapAxes(bodyB.vertices, bodyA.vertices, bodyB.axes)

		if (overlapBA.overlap <= 0) then
			collision.collided = false
			return collision
		end

		if (overlapAB.overlap < overlapBA.overlap) then
			minOverlap = overlapAB
			collision.axisBody = bodyA
		else
			minOverlap = overlapBA
			collision.axisBody = bodyB
		end

		-- important for reuse later
		collision.axisNumber = minOverlap.axisNumber
	end

	collision.bodyA = bodyA.id < bodyB.id and bodyA or bodyB
	collision.bodyB = bodyA.id < bodyB.id and bodyB or bodyA
	collision.collided = true
	collision.depth = minOverlap.overlap
	collision.parentA = collision.bodyA.parent
	collision.parentB = collision.bodyB.parent

	bodyA = collision.bodyA
	bodyB = collision.bodyB

	-- ensure normal is facing away from bodyA
	-- local vx, vy = vectorSub(bodyB.position.x, bodyB.position.y, bodyA.position.x, bodyA.position.y)
	-- local vx, vy = bodyB.position.x - bodyA.position.x, bodyB.position.y - bodyA.position.y

	local minOverlapAxisX, minOverlapAxisY = minOverlap.axis.x, minOverlap.axis.y


	-- if (vectorDot(minOverlapAxisX, minOverlapAxisY, vx, vy) < 0) then

	if ( (minOverlapAxisX * (bodyB.position.x - bodyA.position.x)) + (minOverlapAxisY * (bodyB.position.y - bodyA.position.y)) < 0) then
		collision.normal = {
			x = minOverlapAxisX,
			y = minOverlapAxisY
		}
	else
		collision.normal = {
			x = -minOverlapAxisX,
			y = -minOverlapAxisY
		}
	end

	local collisionNormalX, collisionNormalY = 	collision.normal.x, collision.normal.y

	-- collision.tangent = Vector.perp(collision.normal)
	collision.tangent = {
		x = -collision.normal.y,
		y = collision.normal.x
	}

	collision.penetration = collision.penetration or {}
	collision.penetration.x = collisionNormalX * collision.depth
	collision.penetration.y = collisionNormalY * collision.depth

	-- find support points, there is always either exactly one or two
	local verticesB = SATFindSupports(bodyA, bodyB, collisionNormalX, collisionNormalY)
	-- local verticesB = SATFindSupports(bodyA, bodyB, collision.normal)
	local supports = {}

	-- find the supports from bodyB that are inside bodyA
	if (VerticesContains(bodyA.vertices, verticesB[1])) then
		table.insert(supports, verticesB[1])
		-- supports[#supports+1] =
	end

	if (VerticesContains(bodyA.vertices, verticesB[2])) then
		table.insert(supports, verticesB[2])
		-- supports[#supports+1] = verticesB[2]
	end

	-- find the supports from bodyA that are inside bodyB

	if (#supports < 2) then
		-- vectorNeg
		local verticesA = SATFindSupports(bodyB, bodyA, -collisionNormalX, -collisionNormalY)
		-- local verticesA = SATFindSupports(bodyB, bodyA, Vector.neg(collision.normal))

		if (VerticesContains(bodyB.vertices, verticesA[1])) then
			supports[#supports+1] = verticesA[1]
		end

		if (#supports < 2 and VerticesContains(bodyB.vertices, verticesA[2])) then
			supports[#supports+1] = verticesA[2]
		end
	end

	-- account for the edge case of overlapping but no vertex containment
	if (#supports < 1) then
		supports = {verticesB[1]}
	end

	collision.supports = supports

	return collision
end

function SAT.collides_notoptimised(bodyA, bodyB, previousCollision)

	-- print('SAT.collides')

	local canReusePrevCol = false

	local overlapAB,
		overlapBA,
		minOverlap,
		minOverlapAxisX, minOverlapAxisY,
		collision

	if (previousCollision) then
		-- estimate total motion
		local parentA = bodyA.parent
		local parentB = bodyB.parent
		local motion = parentA.speed * parentA.speed + parentA.angularSpeed * parentA.angularSpeed
				   + parentB.speed * parentB.speed + parentB.angularSpeed * parentB.angularSpeed

		-- we may be able to (partially) reuse collision result
		-- but only safe if collision was resting
		canReusePrevCol = previousCollision and previousCollision.collided and motion < 0.2

		-- reuse collision object
		collision = previousCollision
	else
		collision = {
			collided = false,
			bodyA = bodyA,
			bodyB = bodyB,
		}
	end

	if (previousCollision and canReusePrevCol) then

		-- if we can reuse the collision result
		-- we only need to test the previously found axis
		local axisBodyA = collision.axisBody
		local axisBodyB = axisBodyA == bodyA and bodyB or bodyA
		local axes = {axisBodyA.axes[previousCollision.axisNumber]}

		minOverlap = SAT._overlapAxes(axisBodyA.vertices, axisBodyB.vertices, axes)
		collision.reused = true

		if (minOverlap.overlap <= 0) then
			collision.collided = false
			return collision
		end
	else
		-- if we can't reuse a result, perform a full SAT test

		overlapAB = SAT._overlapAxes(bodyA.vertices, bodyB.vertices, bodyA.axes)

		if (overlapAB.overlap <= 0) then
			collision.collided = false
			return collision
		end

		overlapBA = SAT._overlapAxes(bodyB.vertices, bodyA.vertices, bodyB.axes)

		if (overlapBA.overlap <= 0) then
			collision.collided = false
			return collision
		end

		if (overlapAB.overlap < overlapBA.overlap) then
			minOverlap = overlapAB
			collision.axisBody = bodyA
		else
			minOverlap = overlapBA
			collision.axisBody = bodyB
		end

		-- important for reuse later
		collision.axisNumber = minOverlap.axisNumber
	end

	collision.bodyA = bodyA.id < bodyB.id and bodyA or bodyB
	collision.bodyB = bodyA.id < bodyB.id and bodyB or bodyA
	collision.collided = true
	collision.depth = minOverlap.overlap
	collision.parentA = collision.bodyA.parent
	collision.parentB = collision.bodyB.parent

	bodyA = collision.bodyA
	bodyB = collision.bodyB

	minOverlapAxisX, minOverlapAxisY = 	minOverlap.axis.x, 	minOverlap.axis.y
	-- ensure normal is facing away from bodyA
	-- v1
	-- if (Vector.dot(minOverlap.axis, Vector.sub(bodyB.position, bodyA.position)) < 0) then
	-- v2

	if ((minOverlapAxisX * (bodyB.position.x - bodyA.position.x)) + (minOverlapAxisY * (bodyB.position.y - bodyA.position.y)) < 0) then
		collision.normal = {
			x = minOverlapAxisX,
			y = minOverlapAxisY
		}
	else
		collision.normal = {
			x = -minOverlapAxisX,
			y = -minOverlapAxisY
		}
	end

	-- v1
	-- collision.tangent = Vector.perp(collision.normal)
	-- v2
	collision.tangent = { x = -collision.normal.y, y = collision.normal.x }

	collision.penetration = collision.penetration or {}
	collision.penetration.x = collision.normal.x * collision.depth
	collision.penetration.y = collision.normal.y * collision.depth

	-- find support points, there is always either exactly one or two
	local verticesB = SAT._findSupports(bodyA, bodyB, collision.normal.x, collision.normal.y)
	local supports = {}

	-- find the supports from bodyB that are inside bodyA
	if (Vertices.contains(bodyA.vertices, verticesB[1])) then
		supports[#supports+1] = verticesB[1]
	end

	if (Vertices.contains(bodyA.vertices, verticesB[2])) then
		supports[#supports+1] = verticesB[2]
	end

	-- find the supports from bodyA that are inside bodyB

	if (#supports < 2) then
		local verticesA = SAT._findSupports(bodyB, bodyA, -collision.normal.x, -collision.normal.y)

		if (Vertices.contains(bodyB.vertices, verticesA[1])) then
			supports[#supports+1] = verticesA[1]
		end

		if (#supports < 2 and Vertices.contains(bodyB.vertices, verticesA[2])) then
			supports[#supports+1] = verticesA[2]
		end
	end

	-- account for the edge case of overlapping but no vertex containment
	if (#supports < 1) then
		supports = {verticesB[1]}
	end

	collision.supports = supports

	return collision
end

--[[
 * Find the overlap between two sets of vertices.
 * @method _overlapAxes
 * @private
 * @param {} verticesA
 * @param {} verticesB
 * @param {} axes
 * @return result
 ]]--


function SAT._overlapAxes(verticesA, verticesB, axes)

	-- print('SAT._overlapAxes')

	local projectionA = Vector._temp[1]
	local projectionB = Vector._temp[2]
	local resultOverlap = math.huge
	local resultAxis = nil
	local resultAxisNumber = nil

	local axis, axisX, axisY,
		overlap

	for i = 1, #axes do

		axis = axes[i]
		axisX, axisY = axis.x, axis.y

		SATProjectToAxis(projectionA, verticesA, axisX, axisY)
		SATProjectToAxis(projectionB, verticesB, axisX, axisY)

		overlap = math.min(projectionA.max - projectionB.min, projectionB.max - projectionA.min)

		if (overlap <= 0) then
			return {overlap = overlap}
		end

		if (overlap < resultOverlap) then
			resultOverlap = overlap
			resultAxis = axis
			resultAxisNumber = i
		end
	end

	return resultAxisNumber and {overlap = resultOverlap, axis = resultAxis, axisNumber = resultAxisNumber } or {overlap = resultOverlap}
end

SATOverlapAxes = SAT._overlapAxes

--[[
 * Projects vertices on an axis and returns an interval.
 * @method _projectToAxis
 * @private
 * @param {} projection
 * @param {} vertices
 * @param {} axis
 ]]--

function SAT._projectToAxis(projection, vertices, axisx, axisy)

	-- v1
	-- local min = vectorDot(vertices[1].x, vertices[1].y, axisx, axisy)

	-- v2
	local min = (vertices[1].x * axisx) + (vertices[1].y * axisy)

	local max = min
	local dot, vertex

	for i = 2, #vertices do

		vertex = vertices[i]

		-- v1
		-- dot = vectorDot(vertex.x, vertex.y, axisx, axisy)

		-- v2
		dot = (vertex.x * axisx) + (vertex.y * axisy)

		if (dot > max) then
			max = dot
		elseif (dot < min) then
			min = dot
		end
	end

	projection.min = min
	projection.max = max
end

SATProjectToAxis = SAT._projectToAxis
--[[
 * Finds supporting vertices given two bodies along a given direction using hill-climbing.
 * @method _findSupports
 * @private
 * @param {} bodyA
 * @param {} bodyB
 * @param {} normal
 * @return [vector]
 ]]--

 function SAT._findSupports(bodyA, bodyB, normalX, normalY)

	 local nearestDistance = math.huge
	 local	vertexToBody = Vector._temp[1]
	 local	vertices = bodyB.vertices
	 local	bodyAPosition = bodyA.position

	 local	distance,
			 vertex,
			 vertexA,
			 vertexB,
			 vertexX, vertexY

	 -- find closest vertex on bodyB
	 for i = 1, #vertices do

		 vertex = vertices[i]
		 -- vertexX, vertexY = vertex.x, vertex.y

		 vertexToBody.x = vertex.x - bodyAPosition.x
		 vertexToBody.y = vertex.y - bodyAPosition.y

		 -- distance = -Vector.dot(normal, vertexToBody)
		 -- distance = - vectorDot(normalX, normalY, vertexToBody.x, vertexToBody.y)

		 distance = - ((normalX * vertexToBody.x) + (normalY * vertexToBody.y))

		 if (distance < nearestDistance) then
			 nearestDistance = distance
			 vertexA = vertex
		 end
	 end

	 -- find next closest vertex using the two connected to it
	 local prevIndex = vertexA.index - 1 >= 1 and vertexA.index - 1 or #vertices

	 vertex = vertices[prevIndex]
	 vertexToBody.x = vertex.x - bodyAPosition.x
	 vertexToBody.y = vertex.y - bodyAPosition.y

	 -- nearestDistance = -Vector.dot(normal, vertexToBody)
	 -- nearestDistance = - vectorDot(normalX, normalY, vertexToBody.x, vertexToBody.y)
	 nearestDistance = -((normalX * vertexToBody.x) + (normalY * vertexToBody.y))

	 vertexB = vertex

	 local nextIndex = (vertexA.index + 1) % #vertices
	 	nextIndex = nextIndex ~= 0 and nextIndex or #vertices

	 vertex = vertices[nextIndex]
	 vertexToBody.x = vertex.x - bodyAPosition.x
	 vertexToBody.y = vertex.y - bodyAPosition.y
	 -- distance = -Vector.dot(normal, vertexToBody)
	 -- distance = - vectorDot(normalX, normalY, vertexToBody.x, vertexToBody.y)
	 distance = -((normalX * vertexToBody.x) + (normalY * vertexToBody.y))

	 if (distance < nearestDistance) then
		 vertexB = vertex
	 end

	 return {vertexA, vertexB}
end

function SAT._findSupports_SRC(bodyA, bodyB, normal)

		local nearestDistance = math.huge
		local	vertexToBody = Vector._temp[1]
		local	vertices = bodyB.vertices
		local	bodyAPosition = bodyA.position

		local	distance,
			vertex,
			vertexA,
			vertexB;

		-- find closest vertex on bodyB
		for i = 1, #vertices do

			vertex = vertices[i];
			vertexToBody.x = vertex.x - bodyAPosition.x
			vertexToBody.y = vertex.y - bodyAPosition.y
			distance = -Vector.dot(normal, vertexToBody)

			if (distance < nearestDistance) then
				nearestDistance = distance
				vertexA = vertex
			end
		end

		-- find next closest vertex using the two connected to it
		local prevIndex = vertexA.index - 1 >= 1 and vertexA.index - 1 or #vertices

		vertex = vertices[prevIndex]
		vertexToBody.x = vertex.x - bodyAPosition.x
		vertexToBody.y = vertex.y - bodyAPosition.y
		nearestDistance = -Vector.dot(normal, vertexToBody)
		vertexB = vertex

		local nextIndex = (vertexA.index + 1) % #vertices
		nextIndex = nextIndex ~= 0 and 	nextIndex or #vertices

		vertex = vertices[nextIndex]
		vertexToBody.x = vertex.x - bodyAPosition.x
		vertexToBody.y = vertex.y - bodyAPosition.y
		distance = -Vector.dot(normal, vertexToBody)
		if (distance < nearestDistance) then
			vertexB = vertex
		end

		return {vertexA, vertexB}
end

function SAT._findSupports__(bodyA, bodyB, normalX, normalY)

	-- print('SAT._findSupports')

	local nearestDistance = math.huge -- Number.MAX_VALUE
	-- local vertexToBody = Vector._temp[1]
	-- local vertexToBodyX, vertexToBodyY = 0, 0
	local vertices = bodyB.vertices
	local bodyAPosition = bodyA.position
	local bodyAPositionX, bodyAPositionY = 	bodyAPosition.x, bodyAPosition.y

	local distance,
		vertex,
		vertexA,vertexB,
		vertexX, vertexY,
		vertexAIndex

	-- find closest vertex on bodyB

	for i = 1, #vertices do
		vertex = vertices[i]
		vertexX, vertexY = vertex.x, vertex.y

		-- v1
		-- vertexToBody.x = vertex.x - bodyAPosition.x
		-- vertexToBody.y = vertex.y - bodyAPosition.y

		-- v2
		-- vertexToBodyX = vertex.x - bodyAPositionX
		-- vertexToBodyY = vertex.y - bodyAPositionY

		-- v1
		-- distance = -vectorDot(normalX, normalY, vertexToBody.x, vertexToBody.y)

		-- v2
		-- distance = -(normalX * vertexToBody.x + normalY * vertexToBody.y)
		distance = -(normalX * (vertexX - bodyAPositionX) + normalY * (vertexY - bodyAPositionY))

		if (distance < nearestDistance) then
			nearestDistance = distance
			vertexA = vertex
			vertexAIndex =vertex.index
		end
	end

	-- find next closest vertex using the two connected to it
	local prevIndex = vertexAIndex - 1 >= 1 and vertexAIndex - 1 or #vertices
	vertex = vertices[prevIndex]
	vertexX, vertexY = vertex.x, vertex.y

	-- v1
	-- vertexToBody.x = vertex.x - bodyAPosition.x
	-- vertexToBody.y = vertex.y - bodyAPosition.y

	-- v2
	-- vertexToBodyX = vertex.x - bodyAPositionX
	-- vertexToBodyY = vertex.y - bodyAPositionY

	-- v1
	-- nearestDistance = -vectorDot(normalX, normalY, vertexToBody.x, vertexToBody.y)

	-- v2
	-- nearestDistance = -(normalX * vertexToBody.x + normalY * vertexToBody.y)
	nearestDistance = -(normalX * (vertexX - bodyAPositionX) + normalY * (vertexY - bodyAPositionY))

	vertexB = vertex

	local nextIndex = (vertexAIndex + 1) % #vertices
		nextIndex = nextIndex ~= 0 and nextIndex or #vertices

	vertex = vertices[nextIndex]

	-- v1
	-- vertexToBody.x = vertex.x - bodyAPosition.x
	-- vertexToBody.y = vertex.y - bodyAPosition.y

	-- v2
	-- vertexToBodyX = vertex.x - bodyAPositionX
	-- vertexToBodyY = vertex.y - bodyAPositionY

	-- v1
	-- distance = -vectorDot(normalX, normalY, vertexToBody.x, vertexToBody.y)

	-- v2
	-- distance = -(normalX * vertexToBody.x + normalY * vertexToBody.y)
	distance = -(normalX * (vertexX - bodyAPositionX) + normalY * (vertexY - bodyAPositionY))

	if (distance < nearestDistance) then
		vertexB = vertex
	end

	return {vertexA, vertexB}
end

SATFindSupports = SAT._findSupports


