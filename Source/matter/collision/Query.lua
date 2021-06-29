--[[
* The `Matter.Query` module contains methods for performing collision queries.
*
* See the included usage [examples](https://github.com/liabru/matter-js/tree/master/examples).
*
* @class Query
]]--

import 'matter/geometry/Vector'
import 'matter/collision/SAT'
import 'matter/geometry/Bounds'
import 'matter/geometry/Vertices'

Query = {}
Query.__index = Query

--[[
 * Returns a list of collisions between `body` and `bodies`.
 * @method collides
 * @param {body} body
 * @param {body[]} bodies
 * @return {object[]} Collisions
 ]]--

function Query.collides(body, bodies)
	local collisions = {}
	local n = #bodies

	for i = 1, n do
		local bodyA = bodies[i]

		if (Bounds.overlaps(bodyA.bounds, body.bounds)) then

			local p = #bodyA.parts
			for j = (p == 1 and 1 or 2), p do
				local part = bodyA.parts[j]

				if (Bounds.overlaps(part.bounds, body.bounds)) then
					local collision = SAT.collides(part, body)

					if (collision.collided) then
						table.insert(collisions, collision)
						break
					end
				end
			end
		end
	end

	return collisions
end

--[[
 * Casts a ray segment against a set of bodies and returns all collisions, ray width is optional. Intersection points are not provided.
 * @method ray
 * @param {body[]} bodies
 * @param {vector} startPoint
 * @param {vector} endPoint
 * @param {number} [rayWidth]
 * @return {object[]} Collisions
 ]]--

function Query.ray(bodies, startPoint, endPoint, rayWidth)

	rayWidth = rayWidth or 1e-100

	local rayAngle = Vector.angle(startPoint, endPoint)
	local rayLength = Vector.magnitude(Vector.sub(startPoint, endPoint))
	local rayX = (endPoint.x + startPoint.x) * 0.5
	local rayY = (endPoint.y + startPoint.y) * 0.5
	local ray = Bodies.rectangle(rayX, rayY, rayLength, rayWidth, { angle = rayAngle })
	local collisions = Query.collides(ray, bodies)
	local n = #collisions

	for i = 1, n do
		local collision = collisions[i]
		collision.body, collision.bodyB = collision.bodyA, collision.bodyA
	end

	return collisions
end

--[[
 * Returns all bodies whose bounds are inside (or outside if set) the given set of bounds, from the given set of bodies.
 * @method region
 * @param {body[]} bodies
 * @param {bounds} bounds
 * @param {bool} [outside=false]
 * @return {body[]} The bodies matching the query
 ]]--

function Query.region(bodies, bounds, outside)

	local result = {}
	local n = #bodies

	for i = 1, n do
		local body = bodies[i]
		local overlaps = Bounds.overlaps(body.bounds, bounds)

		if ((overlaps and not outside) or (not overlaps and outside)) then
			table.insert(result, body)
		end
	end

	return result
end

--[[
 * Returns all bodies whose vertices contain the given point, from the given set of bodies.
 * @method point
 * @param {body[]} bodies
 * @param {vector} point
 * @return {body[]} The bodies matching the query
 ]]--
function Query.point(bodies, point)

	local result = {}
	local n = #bodies

	for i = 1, n do

		local body = bodies[i]

		if (Bounds.contains(body.bounds, point)) then

			local p = #body.parts

			for j = (p == 1 and 1 or 2), n do
				local part = body.parts[j]

				if (Bounds.contains(part.bounds, point) and Vertices.contains(part.vertices, point)) then
					table.insert(result, body)
					break
				end
			end
		end
	end

	return result
end

