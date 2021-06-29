--[[
* The `Matter.Vertices` module contains methods for creating and manipulating sets of vertices.
* A set of vertices is an array of `Matter.Vector` with additional indexing properties inserted by `Vertices.create`.
* A `Matter.Body` maintains a set of vertices to represent the shape of the object (its convex hull).
*
* See the included usage [examples](https:--github.com/liabru/matter-js/tree/master/examples).
*
* @class Vertices
]]--

import 'matter/core/Common'
import 'matter/geometry/Vector'

local geom = playdate.geometry

Vertices = {}
Vertices.__index = Vertices


--[[
* Creates a new set of `Matter.Body` compatible vertices.
* The `points` argument accepts an array of `Matter.Vector` points orientated around the origin `(0, 0)`, for example:
*
*	 [{ x: 0, y: 0 }, { x: 25, y: 50 }, { x: 50, y: 0 }]
*
* The `Vertices.create` method returns a new array of vertices, which are similar to Matter.Vector objects,
* but with some additional references required for efficient collision detection routines.
*
* Vertices must be specified in clockwise order.
*
* Note that the `body` argument is not optional, a `Matter.Body` reference must be provided.
*
* @method create
* @param {vector[]} points
* @param {body} body
]]--

function Vertices.create(points, body)

	local vertices = {}
	-- local point

	for i = 1, #points do
		local point = points[i]

		table.insert(vertices, {
			x = point.x,
			y = point.y,
			index = i,
			body = body,
			isInternal = false
		})
	end

	return vertices
end

--[[
	 * Parses a string containing ordered x y pairs separated by spaces (and optionally commas),
	 * into a `Matter.Vertices` object for the given `Matter.Body`.
	 * For parsing SVG paths, see `Svg.pathToVertices`.
	 * @method fromPath
	 * @param {string} path
	 * @param {body} body
	 * @return {vertices} vertices
]]--

function Vertices.fromPath(path, body)

	 -- /L?\s*([-\d.e]+)[\s,]*([-\d.e]+)*/ig
	local pathPattern = 'L?%s*([-%d.e]+)[%s,]*([-%d.e]+)'
	local points = {}

	string.gsub(path, pathPattern, function(x, y)
		table.insert(points, {x = tonumber(x), y = tonumber(y)})
	end)

	return Vertices.create(points, body)
end

-- Vertices.fromPath = function(path, body) {
-- 	var pathPattern = /L?\s*([-\d.e]+)[\s,]*([-\d.e]+)*/ig,
-- 	points = [];
--
-- 	path.replace(pathPattern, function(match, x, y) {
-- 		points.push({ x: parseFloat(x), y: parseFloat(y) });
-- 	});
--
-- 	return Vertices.create(points, body);
-- };

--[[
	 * Returns the centre (centroid) of the set of vertices.
	 * @method centre
	 * @param {vertices} vertices
	 * @return {vector} The centre point
 ]]--
function Vertices.centre__(vertices)

	local centreX, centreY = 0, 0
	local n = #vertices
	local aX, aY,
		bX, bY
		-- tempX, tempY,
		scalar,
		j

	for i = 1, n do

		j = (i + 1) % n
		j = j ~= 0 and j or n

		aX, aY = vertices[i].x, vertices[i].y
		bX, bY = vertices[j].x, vertices[j].y

		-- v1. src
		-- tempX, tempY = vectorAdd(aX, aY, bX, bY)
		-- scalar = vectorCross(aX, aY, bX, bY)
		-- tempX, tempY = vectorMult(tempX, tempY,  scalar)
		-- centreX, centreY = vectorAdd(centreX, centreY, tempX, tempY)

		-- v2. w/o vector utils
		-- tempX, tempY = aX + bX, aY + bY
		-- tempX, tempY = (aX + bX) * scalar, (aY + bY) * scalar
		-- centreX, centreY = centreX + tempX, centreY + tempY

		-- v3.
		scalar = (aX*bY) - (aY * bX)
		centreX, centreY = centreX + ((aX + bX) * scalar), centreY + ((aY + bY) * scalar)

	end

	-- return vectorDiv(centreX, centreY, 6 * Vertices.area(vertices, true))

	scalar = 6 * Vertices.area(vertices, true)
	return { x = centreX / scalar, y = centreY / scalar }

end

function Vertices.centre(vertices)

	local area = Vertices.area(vertices, true)
	local n = #vertices
	local centre = { x= 0, y= 0 }
	local cross,
			temp,
			j

	for i = 1, n do

		j = (i + 1) % n
		j = j ~= 0 and j or n

		cross = Vector.cross(vertices[i], vertices[j])
		temp = Vector.mult(Vector.add(vertices[i], vertices[j]), cross)
		centre = Vector.add(centre, temp)
	end

	return Vector.div(centre, 6 * area)
end

--[[
	 * Returns the average (mean) of the set of vertices.
	 * @method mean
	 * @param {vertices} vertices
	 * @return {vector} The average point
]]--
function Vertices.mean(vertices)

	local averageX, averageY = 0, 0
	local n = #vertices

	for i = 1, n do
		averageX += vertices[i].x
		averageY += vertices[i].y
	end

	-- local res = vectorDiv(averageX, averageY, n)
	-- return res.x, res.y

	return { x = averageX / n, y = averageY / n }
end

--[[
	 * Returns the area of the set of vertices.
	 * @method area
	 * @param {vertices} vertices
	 * @param {bool} signed
	 * @return {number} The area
 ]]--

 function Vertices.area(vertices, signed)
	local area = 0
	local j = #vertices

	for i = 1, #vertices do
		area += (vertices[j].x - vertices[i].x) * (vertices[j].y + vertices[i].y)
		j = i
	end

	if (signed) then
		return area / 2
	end

	return math.abs(area) / 2
end

--[[
	 * Returns the moment of inertia (second moment of area) of the set of vertices given the total mass.
	 * @method inertia
	 * @param {vertices} vertices
	 * @param {number} mass
	 * @return {number} The polygon's moment of inertia
]]--
function Vertices.inertia(vertices, mass)
		local numerator = 0
		local denominator = 0
		local n = #vertices
		local cross,
			a, b,
			j

		-- find the polygon's moment of inertia, using second moment of area
		-- from equations at http:--www.physicsforums.com/showthread.php?t=25293

		for i = 1, n do
			j = (i + 1) % n
			j = j ~= 0 and j or n
			aX, aY = vertices[i].x, vertices[i].y
			bX, bY = vertices[j].x, vertices[j].y
			-- cross = math.abs(vectorCross(bX, bY, aX, aY))

			cross = math.abs(bX * aY - bY * aX)
			-- numerator += cross * (vectorDot(bX, bY, bX, bY) + vectorDot(bX, bY, aX, aY) + vectorDot(aX, aY, aX, aY))

			numerator += cross * ((bX * bX + bY * bY) + (bX * aX + bY * aY) + (aX * aX + aY * aY))
			denominator += cross
		end

		return (mass / 6) * (numerator / denominator)
end

--[[
	 * Translates the set of vertices in-place.
	 * @method translate
	 * @param {vertices} vertices
	 * @param {vector} vector
	 * @param {number} scalar
]]--
function Vertices.translate(vertices, vector, scalar)

		local vx, vy = vector.x, vector.y

		if (scalar) then
			for i = 1, #vertices do
				vertices[i].x += vx * scalar
				vertices[i].y += vy * scalar
			end
		else
			for i = 1, #vertices do
				vertices[i].x += vx
				vertices[i].y += vy
			end
		end

		return vertices
end

--[[
	 * Rotates the set of vertices in-place.
	 * @method rotate
	 * @param {vertices} vertices
	 * @param {number} angle
	 * @param {vector} point
]]--
function Vertices.rotate(vertices, angle, point)

	if (angle == 0) then
		return
	end

	local cos = math.cos(angle)
	local sin = math.sin(angle)
	local px, py = 	point.x, point.y
	local dx, dy

	for i = 1, #vertices do
		local vertice = vertices[i]
		dx = vertice.x - px
		dy = vertice.y - py

		vertice.x = px + (dx * cos - dy * sin)
		vertice.y = py + (dx * sin + dy * cos)
	end

	return vertices
end

--[[
	 * Returns `true` if the `point` is inside the set of `vertices`.
	 * @method contains
	 * @param {vertices} vertices
	 * @param {vector} point
	 * @return {boolean} True if the vertices contains point, otherwise false
 ]]--
 function Vertices.contains(vertices, point)

	local px, py = 	point.x, point.y
	local n = #vertices

	local vertice,
		nextVertice,
		nextVerticeIndex,
		vx, vy

	for i = 1, n do
		vertice = vertices[i]
		vx, vy = vertice.x, vertice.y

		nextVerticeIndex = (i + 1) % n
		nextVertice = vertices[nextVerticeIndex ~= 0 and nextVerticeIndex or n]

		if ((px - vx) * (nextVertice.y - vy) + (py - vy) * (vx - nextVertice.x) > 0) then
			return false
		end
	end

	return true
end

--[[
	 * Scales the vertices from a point (default is centre) in-place.
	 * @method scale
	 * @param {vertices} vertices
	 * @param {number} scaleX
	 * @param {number} scaleY
	 * @param {vector} point
]]--

function Vertices.scale(vertices, scaleX, scaleY, point)

	if (scaleX == 1 and scaleY == 1) then
		return vertices
	end

	point = point or Vertices.centre(vertices)

	local px, py = 	point.x, point.y
	local vertex
		-- deltaX, deltaY

	for i = 1, #vertices do
		vertex = vertices[i]

		-- v1
		-- deltaX, deltaY = vectorSub(vertex.x, vertex.y, px, py)
		-- vertex.x = px + deltaX * scaleX
		-- vertex.y = py + deltaY * scaleY

		-- v2
		vertex.x = px + (vertex.x - px) * scaleX
		vertex.y = py + (vertex.y - py) * scaleY
	end

	return vertices
end

--[[
	 * Chamfers a set of vertices by giving them rounded corners, returns a new set of vertices.
	 * The radius parameter is a single number or an array to specify the radius for each vertex.
	 * @method chamfer
	 * @param {vertices} vertices
	 * @param {number[]} radius
	 * @param {number} quality
	 * @param {number} qualityMin
	 * @param {number} qualityMax
]]--

function Vertices.chamfer(vertices, radius, quality, qualityMin, qualityMax)

	if (type(radius) == 'number') then
		radius = {radius}
	else
		radius = radius or {8}
	end

	-- quality defaults to -1, which is auto
	quality = quality or -1
	qualityMin = qualityMin or 2
	qualityMax = qualityMax or 14

	local n = #vertices
	local newVertices = {}

	local vertex,
		prevVertex,	prevNormalX, prevNormalY,
		nextVertex, nextNormalX, nextNormalY,
		currentRadius,
		radiusVectorX, radiusVectorY
		-- midNormalX, midNormalY,
		scaledVertexX, scaledVertexY,
		precision,
		theta,
		scalar
		-- vx, vy

	for i = 1, n do
		repeat

			vertex = vertices[i]
			currentRadius = radius[i <= #radius and i or #radius]

			if (currentRadius == 0) then
				table.insert(newVertices, vertex)
				break
			end

			prevVertex = vertices[i - 1 >= 1 and i - 1 or n]
			nextVertex = (i + 1) % n
			nextVertex = vertices[nextVertex ~= 0 and nextVertex or n]
			vertexX, vertexY = vertex.x, vertex.y

			prevNormalX, prevNormalY = vectorNormalise(
				vertexY - prevVertex.y,
				prevVertex.x - vertexX
			)

			nextNormalX, nextNormalY = vectorNormalise(
				nextVertex.y - vertexY,
				vertexX - nextVertex.x
			)

			-- v1
			-- radiusVectorX, radiusVectorY = vectorMult(prevNormalX, prevNormalY, currentRadius)

			-- v2
			radiusVectorX, radiusVectorY = prevNormalX * currentRadius, prevNormalY * currentRadius

			-- v1
			-- vx, vy = vectorAdd(prevNormalX, prevNormalY, nextNormalX, nextNormalY)

			-- v2
			-- vx, vy = prevNormalX + nextNormalX, prevNormalY + nextNormalY

			-- v1
			-- midNormalX, midNormalY = vectorNormalise(vectorMult(vx, vy, 0.5))

			-- v2
			midNormalX, midNormalY = vectorNormalise((prevNormalX + nextNormalX) * 0.5, (prevNormalY + nextNormalY) * 0.5)

			-- mult midNormal and diagonalRadius
			-- v1
			-- vx, vy = vectorMult(midNormalX, midNormalY, math.sqrt(2 * math.pow(currentRadius, 2)))

			-- v2
			scalar = math.sqrt(2 * math.pow(currentRadius, 2))
			-- vx, vy = midNormalX * scalar, midNormalY * scalar

			-- v1
			-- scaledVertexX, scaledVertexY = vectorSub(vertexX, vertexY, vx, vy)

			-- v2
			scaledVertexX, scaledVertexY = vertexX - ( midNormalX * scalar), vertexY - (midNormalY * scalar)

			precision = quality

			if (quality == -1) then
				-- automatically decide precision
				precision = math.pow(currentRadius, 0.32) * 1.75
			end

			precision = Common.clamp(precision, qualityMin, qualityMax)

			-- use an even value for precision, more likely to reduce axes by using symmetry

			if (precision % 2 == 1) then
				precision += 1
			end

			-- alpha / 	precision
			-- v1
			-- theta = math.acos(vectorDot(prevNormalX, prevNormalY, nextNormalX, nextNormalY)) / precision

			-- v2
			theta = math.acos(prevNormalX * nextNormalX + prevNormalY * nextNormalY) / precision

			for j = 0, precision do

				-- v1
				-- vx, vy = vectorRotate(radiusVectorX, radiusVectorY, theta * j)
				-- vx, vy = vectorAdd(vx, vy, scaledVertexX, scaledVertexY)
				-- table.insert(newVertices,  {x = vx, y = vy})

				-- v2
				cos, sin = math.cos(theta * j), math.sin(theta * j)

				table.insert(newVertices,  {
					x = (radiusVectorX * cos - radiusVectorY * sin) + scaledVertexX,
					y = (radiusVectorX * sin + radiusVectorY * cos) + scaledVertexY
				})
			end

			break
		until true
	end

	return newVertices
end

--[[
	 * Sorts the input vertices into clockwise order in place.
	 * @method clockwiseSort
	 * @param {vertices} vertices
	 * @return {vertices} vertices
 ]]--

 function Vertices.clockwiseSort(vertices)

	local centre = Vertices.mean(vertices)
	local centreX, centreY = centre.x, centre.y

	local tmp = {}


	-- prepare sort
	for key, vertex in pairs(vertices) do

		-- v1
		-- table.insert(tmp, key, vectorAngle(centreX, centreY, vertex.x, vertex.y))

		-- v2
		table.insert(tmp, key, math.atan2(vertex.y - centreY, vertex.x - centreX))
	end

	table.sort(vertices, function (vertexA, vertexB)
		return tmp[vertexA.index] < tmp[vertexB.index]
	end)

	return vertices
end

--[[
	 * Returns true if the vertices form a convex shape (vertices must be in clockwise order).
	 * @method isConvex
	 * @param {vertices} vertices
	 * @return {bool} `true` if the `vertices` are convex, `false` if not (or `null` if not computable).
 ]]--

-- http://paulbourke.net/geometry/polygonmesh/
-- Copyright (c) Paul Bourke (use permitted)

 function Vertices.isConvex(vertices)

	local flag = 0
	local n = #vertices
	local j, k, z,
		vertice,
		verticeNext,
		verticeAfterNext

	if (n < 3) then
		return nil
	end

	for i = 1, n do

		-- TODO: Optimise me

		j = (i + 1) % n
		k = (i + 2) % n

		vertice = vertices[i]
		verticeNext = vertices[j ~= 0 and j or n]
		verticeAfterNext = vertices[k ~= 0 and k or n]

		z = (verticeNext.x - vertice.x) * (verticeAfterNext.y - verticeNext.y)
		z -= (verticeNext.y - vertice.y) * (verticeAfterNext.x - verticeNext.x)

		if (z < 0) then
			flag |= 1
		elseif (z > 0) then
			flag |= 2
		end

		if (flag == 3) then
			return false
		end
	end

	return (flag ~= 0) and true or nil

end

--[[
	 * Returns the convex hull of the input vertices as a new array of points.
	 * @method hull
	 * @param {vertices} vertices
	 * @return [vertex] vertices
 ]]--

-- http://geomalgorithms.com/a10-_hull-1.html

 function Vertices.hull(vertices)

	local upper = {}
	local lower = {}
	local tmp = {}
	local vertex,
		adx, bdx -- sorting

	-- sort vertices on x-axis (y-axis for ties)

	table.sort(vertices, function(vertexA, vertexB)
		adx = vertexA.x - vertexB.x
		adx = adx ~= 0 and adx or vertexA.y - vertexB.y

		bdx = vertexB.x - vertexA.x
		bdx = bdx ~= 0 and bdx or vertexB.y - vertexA.y

		return adx < bdx
	end)

	-- build lower hull

	local n = #vertices

	-- TODO: Optimise me

	for i = 1, n do

		vertex = vertices[i]

		while (#lower >= 2 and Vector.cross3(lower[#lower - 1], lower[#lower], vertex) <= 0) do
			table.remove(lower)
		end

		table.insert(lower, vertex)
	end

	-- build upper hull
	for i = n, 1, -1 do
		vertex = vertices[i]

		while (#upper >= 2 and Vector.cross3(upper[#upper - 1], upper[#upper], vertex) <= 0) do

			table.remove(upper)
		end

		table.insert(upper, vertex)
	end

	-- concatenation of the lower and upper hulls gives the convex hull
	-- omit last points because they are repeated at the beginning of the other list
	table.remove(upper)
	table.remove(lower)

	return table.union(upper, lower)
end




