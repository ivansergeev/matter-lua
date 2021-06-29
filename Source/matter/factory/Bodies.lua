--[[
* The `Matter.Bodies` module contains factory methods for creating rigid body models
* with commonly used body configurations (such as rectangles, circles and other polygons).
*
* See the included usage [examples](https://github.com/liabru/matter-js/tree/master/examples).
*
* @class Bodies
]]--

-- TODO: true circle bodies

import 'matter/core/Common'
import 'matter/body/Body'
import 'matter/geometry/Bounds'
import 'matter/geometry/Vector'
import 'matter/geometry/Vertices'
import 'matter/libs/PolyDecomp'

Bodies = {}
Bodies.__index = Bodies

--[[
 * Creates a new rigid body model with a rectangle hull.
 * The options parameter is an object that specifies any properties you wish to override the defaults.
 * See the properties section of the `Matter.Body` module for detailed information on what you can pass via the `options` object.
 * @method rectangle
 * @param {number} x
 * @param {number} y
 * @param {number} width
 * @param {number} height
 * @param {object} [options]
 * @return {body} A new rectangle body
 ]]--


function Bodies.rectangle(x, y, width, height, options)
	options = options or {}

	local rectangle = {
		label = 'Rectangle Body',
		position = {
			x = x,
			y = y
		},
		vertices = Vertices.fromPath('L 0 0 L ' .. width .. ' 0 L ' .. width .. ' ' .. height .. ' L 0 ' .. height)
	}

	if (options.chamfer) then
		local chamfer = options.chamfer
		rectangle.vertices = Vertices.chamfer(rectangle.vertices, chamfer.radius, chamfer.quality, chamfer.qualityMin, chamfer.qualityMax)
		options.chamfer = nil
	end

	return Body.create(Common.extend({}, rectangle, options))
end

--[[
 * Creates a new rigid body model with a trapezoid hull.
 * The options parameter is an object that specifies any properties you wish to override the defaults.
 * See the properties section of the `Matter.Body` module for detailed information on what you can pass via the `options` object.
 * @method trapezoid
 * @param {number} x
 * @param {number} y
 * @param {number} width
 * @param {number} height
 * @param {number} slope
 * @param {object} [options]
 * @return {body} A new trapezoid body
 ]]--
function Bodies.trapezoid(x, y, width, height, slope, options)

	options = options or {}
	slope *= 0.5

	local roof = (1 - (slope * 2)) * width

	local x1 = width * slope
	local x2 = x1 + roof
	local x3 = x2 + x1
	local verticesPath

	if (slope < 0.5) then
		verticesPath = 'L 0 0 L ' .. x1 .. ' ' .. (-height) .. ' L ' .. x2 .. ' ' .. (-height) .. ' L ' .. x3 .. ' 0'
	else
		verticesPath = 'L 0 0 L ' .. x2 .. ' ' .. (-height) .. ' L ' .. x3 .. ' 0'
	end

	local trapezoid = {
		label = 'Trapezoid Body',
		position = {
			x = x,
			y = y
		},
		vertices = Vertices.fromPath(verticesPath)
	}

	if (options.chamfer) then
		local chamfer = options.chamfer
		trapezoid.vertices = Vertices.chamfer(trapezoid.vertices, chamfer.radius, chamfer.quality, chamfer.qualityMin, chamfer.qualityMax)
		options.chamfer = nil
	end

	return Body.create(Common.extend({}, trapezoid, options))
end

--[[
 * Creates a new rigid body model with a circle hull.
 * The options parameter is an object that specifies any properties you wish to override the defaults.
 * See the properties section of the `Matter.Body` module for detailed information on what you can pass via the `options` object.
 * @method circle
 * @param {number} x
 * @param {number} y
 * @param {number} radius
 * @param {object} [options]
 * @param {number} [maxSides]
 * @return {body} A new circle body
 ]]--
function Bodies.circle(x, y, radius, options, maxSides)

	options = options or {}

	local circle = {
		label = 'Circle Body',
		circleRadius = radius
	}

	-- approximate circles with polygons until true circles implemented in SAT
	maxSides = maxSides or 25
	local sides = math.ceil(math.max(10, math.min(maxSides, radius)))

	-- optimisation: always use even number of sides (half the number of unique axes)
	if (sides % 2 == 1)	then
		sides += 1
	end

	return Bodies.polygon(x, y, sides, radius, Common.extend({}, circle, options))
end

--[[
 * Creates a new rigid body model with a regular polygon hull with the given number of sides.
 * The options parameter is an object that specifies any properties you wish to override the defaults.
 * See the properties section of the `Matter.Body` module for detailed information on what you can pass via the `options` object.
 * @method polygon
 * @param {number} x
 * @param {number} y
 * @param {number} sides
 * @param {number} radius
 * @param {object} [options]
 * @return {body} A new regular polygon body
 ]]--

function Bodies.polygon(x, y, sides, radius, options)

	options = options or {}

	if (sides < 3)	then
		return Bodies.circle(x, y, radius, options)
	end

	local theta = 2 * math.pi / sides
	local path = ''
	local offset = theta * 0.5

	sides -= 1

	for i = 0, sides do
		local angle = offset + (i * theta)
		local xx = math.cos(angle) * radius
		local yy = math.sin(angle) * radius

		path = path .. 'L ' .. tofixed(xx, 3) .. ' ' .. tofixed(yy, 3) .. ' '
	end

	local polygon = {
		label = 'Polygon Body',
		position = {
			x = x,
			y = y,
		},
		vertices = Vertices.fromPath(path)
	}


	if (options.chamfer) then

		local chamfer = options.chamfer
		polygon.vertices = Vertices.chamfer(polygon.vertices, chamfer.radius, chamfer.quality, chamfer.qualityMin, chamfer.qualityMax)
		options.chamfer = nil
	end

	return Body.create(Common.extend({}, polygon, options))
end

--[[
 * Creates a body using the supplied vertices (or an array containing multiple sets of vertices).
 * If the vertices are convex, they will pass through as supplied.
 * Otherwise if the vertices are concave, they will be decomposed if [poly-decomp.js](https://github.com/schteppe/poly-decomp.js) is available.
 * Note that this process is not guaranteed to support complex sets of vertices (e.g. those with holes may fail).
 * By default the decomposition will discard collinear edges (to improve performance).
 * It can also optionally discard any parts that have an area less than `minimumArea`.
 * If the vertices can not be decomposed, the result will fall back to using the convex hull.
 * The options parameter is an object that specifies any `Matter.Body` properties you wish to override the defaults.
 * See the properties section of the `Matter.Body` module for detailed information on what you can pass via the `options` object.
 * @method fromVertices
 * @param {number} x
 * @param {number} y
 * @param [vector] vertexSets
 * @param {object} [options]
 * @param {bool} [flagInternal=false]
 * @param {number} [removeCollinear=0.01]
 * @param {number} [minimumArea=10]
 * @return {body}
 ]]--

function Bodies.fromVertices(x, y, vertexSets, options, flagInternal, removeCollinear, minimumArea)

	-- print('Bodies.fromVertices')

	-- local decomp = global.decomp or require('poly-decomp')
	local decomp = PolyDecomp

	local body,
		parts,
		isConvex,
		vertices

	options = options or {}
	parts = {}

	flagInternal = type(flagInternal) ~= 'nil' and flagInternal or false
	removeCollinear = type(removeCollinear) ~= 'nil' and removeCollinear or 0.01
	minimumArea = type(minimumArea) ~= 'nil' and minimumArea or 10

	if (not decomp) then
		Common.warn('Bodies.fromVertices: poly-decomp.js required. Could not decompose vertices. Fallback to convex hull.')
	end

	-- ensure vertexSets is an array of arrays
	if (not Common.isArray(vertexSets[1])) then
		vertexSets = {vertexSets}
	end

	local n = #vertexSets

	for v = 1, n do

		vertices = vertexSets[v]
		isConvex = Vertices.isConvex(vertices)

		if (isConvex or not decomp) then

			if (isConvex) then
				vertices = Vertices.clockwiseSort(vertices)
			else
				-- fallback to convex hull when decomposition is not possible
				vertices = Vertices.hull(vertices)
			end

			table.insert(parts, {
				position = {
					x = x,
					y = y
				},
				vertices = vertices
			})
		else
			-- initialise a decomposition

			local concave = {}
			for _, vertex in pairs(vertices) do
				table.insert(concave, {vertex.x, vertex.y})
			end

			-- vertices are concave and simple, we can decompose into parts
			decomp.makeCCW(concave)


			if (removeCollinear ~= false) then
				-- decomp.removeCollinearPoints(concave, removeCollinear)
			end

			-- use the quick decomposition algorithm (Bayazit)
			local decomposed = decomp.quickDecomp(concave)

			-- for each decomposed chunk

			for i = 1, #decomposed do
				repeat
					local chunk = decomposed[i]

					-- convert vertices into the correct structure
					local chunkVertices = {}

					for _, vertices in pairs(chunk) do
						table.insert(chunkVertices, {x = vertices[1], y = vertices[2]})
					end

					-- skip small chunks
					if (minimumArea > 0 and Vertices.area(chunkVertices) < minimumArea) then
						break
					end

					-- create a compound part

					table.insert(parts, {
						position = Vertices.centre(chunkVertices),
						vertices = chunkVertices
					})

				break
				until true
			end
		end
	end

	-- create body parts

	for i = 1, #parts do
		parts[i] = Body.create(Common.extend(parts[i], options))
	end

	-- flag internal edges (coincident part edges)

	if (flagInternal) then

		print('	Flag internal edges (coincident part edges)')

		local coincident_max_dist = 5

		for i = 1, #parts do

			local partA = parts[i]

			for j = i + 1, #parts do

				local partB = parts[j]

				if (Bounds.overlaps(partA.bounds, partB.bounds)) then
					local pav = partA.vertices
					local pbv = partB.vertices

					-- iterate vertices of both parts

					for k = 1, #partA.vertices do

						for z = 1, #partB.vertices do

							-- find distances between the vertices
							local x1 = (k + 1) % #pav
							x1 = x1 ~= 0 and x1 or #pav

							local x2 = (z + 1) % #pbv
							x2 = x2 ~= 0 and x2 or #pbv

							-- local da = Vector.magnitudeSquared(Vector.sub(pav[(k + 1) % #pav], pbv[z]))
							local da = Vector.magnitudeSquared(Vector.sub(pav[x1], pbv[z]))

							-- local db = Vector.magnitudeSquared(Vector.sub(pav[k], pbv[(z + 1) % #pbv]))
							local db = Vector.magnitudeSquared(Vector.sub(pav[k], pbv[x2]))

							-- if both vertices are very close, consider the edge concident (internal)

							if (da < coincident_max_dist and db < coincident_max_dist) then
								print('+')
								pav[k].isInternal = true
								pbv[z].isInternal = true
							end
						end
					end
				end
			end
		end
	end

	if (#parts > 1) then
		-- create the parent body to be returned, that contains generated compound parts

		-- level = 0
		body = Body.createWithParts(Common.extend({ parts = table.deepclone2(parts) }, options))
		-- body = Body.create(Common.extend({ parts = table.deepclone2(parts) }, options))

		Body.setPosition(body, {
			x = x,
			y = y
		})

		return body
	else
		return parts[1]
	end
end

function debugParts(parts)

	for i=1, #parts do

		local vertices = Table{}

		for v=1, #parts[i].vertices do
			local vert = parts[i].vertices[v]
			vertices:push(vert.x)
					:push(vert.y)
		end

		playdate.graphics.drawPolygon(table.unpack(vertices))

	end
end

