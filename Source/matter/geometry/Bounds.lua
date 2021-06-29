--[[
* The `Matter.Bounds` module contains methods for creating and manipulating axis-aligned bounding boxes (AABB).
*
* @class Bounds
]]--


Bounds = {}
Bounds.__index = Bounds


--[[
 * Creates a new axis-aligned bounding box (AABB) for the given vertices.
 * @method create
 * @param {vertices} vertices
 * @return {bounds} A new bounds object
 ]]--

function Bounds.create(vertices)

	-- print('Bounds.create')

	local bounds = {
		min = { x = 0, y = 0 },
		max = { x = 0, y = 0 },
	}

	if (vertices) then
		Bounds.update(bounds, vertices)
	end

	return bounds
end

--[[
 * Updates bounds using the given vertices and extends the bounds given a velocity.
 * @method update
 * @param {bounds} bounds
 * @param {vertices} vertices
 * @param {vector} velocity
 ]]--

function Bounds.update(bounds, vertices, velocity)

	-- print('Bounds.update', #vertices)

	local n = #vertices

	-- Infinity values
	if (not bounds) then
		bounds = { min = {}, max = {} }
	end

	bounds.min.x = math.huge
	bounds.max.x = -math.huge
	bounds.min.y = math.huge
	bounds.max.y = -math.huge

	for i = 1, n do
		local vertex = vertices[i]
		if (vertex.x > bounds.max.x) then bounds.max.x = vertex.x end
		if (vertex.x < bounds.min.x) then bounds.min.x = vertex.x end
		if (vertex.y > bounds.max.y) then bounds.max.y = vertex.y end
		if (vertex.y < bounds.min.y) then bounds.min.y = vertex.y end
	end

	if (velocity) then
		if (velocity.x > 0) then
			bounds.max.x += velocity.x
		else
			bounds.min.x += velocity.x
		end

		if (velocity.y > 0) then
			bounds.max.y += velocity.y
		else
			bounds.min.y += velocity.y
		end
	end
end

--[[
 * Returns true if the bounds contains the given point.
 * @method contains
 * @param {bounds} bounds
 * @param {vector} point
 * @return {boolean} True if the bounds contain the point, otherwise false
 ]]--

function Bounds.contains(bounds, point)
	return (point.x >= bounds.min.x and point.x <= bounds.max.x
		   and point.y >= bounds.min.y and point.y <= bounds.max.y)
end

--[[
 * Returns true if the two bounds intersect.
 * @method overlaps
 * @param {bounds} boundsA
 * @param {bounds} boundsB
 * @return {boolean} True if the bounds overlap, otherwise false
 ]]--
function Bounds.overlaps(boundsA, boundsB)
	return (boundsA.min.x <= boundsB.max.x and boundsA.max.x >= boundsB.min.x
			and boundsA.max.y >= boundsB.min.y and boundsA.min.y <= boundsB.max.y)
end

--[[
 * Translates the bounds by the given vector.
 * @method translate
 * @param {bounds} bounds
 * @param {vector} vector
 ]]--

function Bounds.translate(bounds, vector)
	bounds.min.x += vector.x
	bounds.max.x += vector.x
	bounds.min.y += vector.y
	bounds.max.y += vector.y
end

--[[
 * Shifts the bounds to the given position.
 * @method shift
 * @param {bounds} bounds
 * @param {vector} position
 ]]--

function Bounds.shift(bounds, position)
	local deltaX = bounds.max.x - bounds.min.x
	local deltaY = bounds.max.y - bounds.min.y

	bounds.min.x = position.x
	bounds.max.x = position.x + deltaX
	bounds.min.y = position.y
	bounds.max.y = position.y + deltaY
end
