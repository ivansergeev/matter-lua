-- https://github.com/schteppe/poly-PolyDecomp.js

local tmpPoint1 = {}
local tmpPoint2 = {}
local tmpLine1 = {}
local tmpLine2 = {}

PolyDecomp = {}
PolyDecomp.__index = PolyDecomp


--[[
 * Compute the intersection between two lines.
 * @static
 * @method lineInt
 * @param  {Array}  l1		  Line vector 1
 * @param  {Array}  l2		  Line vector 2
 * @param  {Number} precision   Precision to use when checking if the lines are parallel
 * @return {Array}			  The intersection point.
]]--

function PolyDecomp.lineInt(l1, l2, precision)

	precision = precision or 0
	local i = {0, 0} -- point
	local a1, b1, c1, a2, b2, c2, det -- scalars

	a1 = l1[2][2] - l1[1][2]
	b1 = l1[1][1] - l1[2][1]
	c1 = a1 * l1[1][1] + b1 * l1[1][2]
	a2 = l2[2][2] - l2[1][2]
	b2 = l2[1][1] - l2[2][1]
	c2 = a2 * l2[1][1] + b2 * l2[1][2]
	det = a1 * b2 - a2*b1

	if (not PolyDecomp.scalar_eq(det, 0, precision)) then -- lines are not parallel
		i[1] = (b2 * c1 - b1 * c2) / det
		i[2] = (a1 * c2 - a2 * c1) / det
	end

	return i
end

--[[
 * Checks if two line segments intersects.
 * @method segmentsIntersect
 * @param {Array} p1 The start vertex of the first line segment.
 * @param {Array} p2 The end vertex of the first line segment.
 * @param {Array} q1 The start vertex of the second line segment.
 * @param {Array} q2 The end vertex of the second line segment.
 * @return {Boolean} True if the two line segments intersect
]]--
function PolyDecomp.lineSegmentsIntersect(p1, p2, q1, q2)

	local dx = p2[1] - p1[1]
	local dy = p2[2] - p1[2]
	local da = q2[1] - q1[1]
	local db = q2[2] - q1[2]

	-- segments are parallel
	if((da*dy - db*dx) == 0) then
		return false
	end

	local s = (dx * (q1[2] - p1[2]) + dy * (p1[1] - q1[1])) / (da * dy - db * dx)
	local t = (da * (p1[2] - q1[2]) + db * (q1[1] - p1[1])) / (db * dx - da * dy)

	return ( s >= 0 and s <= 1 and t >= 0 and t <= 1 )
end

--[[
 * Get the area of a triangle spanned by the three given points. Note that the area will be negative if the points are not given in counter-clockwise order.
 * @static
 * @method area
 * @param  {Array} a
 * @param  {Array} b
 * @param  {Array} c
 * @return {Number}
]]--

function PolyDecomp.triangleArea(a, b, c)
	return (((b[1] - a[1]) * (c[2] - a[2])) - ((c[1] - a[1]) * (b[2] - a[2])))
end

function PolyDecomp.isLeft(a, b, c)
	return PolyDecomp.triangleArea(a, b, c) > 0
end

function PolyDecomp.isLeftOn(a, b, c)
	return PolyDecomp.triangleArea(a, b, c) >= 0
end

function PolyDecomp.isRight(a, b, c)
	return PolyDecomp.triangleArea(a, b, c) < 0
end

function PolyDecomp.isRightOn(a,b,c)
	return PolyDecomp.triangleArea(a, b, c) <= 0
end



--[[
 * Check if three points are collinear
 * @method collinear
 * @param  {Array} a
 * @param  {Array} b
 * @param  {Array} c
 * @param  {Number} [thresholdAngle=0] Threshold angle to use when comparing the vectors. The function will return true if the angle between the resulting vectors is less than this value. Use zero for max precision.
 * @return {Boolean}
]]--
function PolyDecomp.collinear(a, b, c, thresholdAngle)

	if( not thresholdAngle) then
		return PolyDecomp.triangleArea(a, b, c) == 0
	else
		local ab = tmpPoint1
		local bc = tmpPoint2

		ab[1] = b[1]-a[1]
		ab[2] = b[2]-a[2]
		bc[1] = c[1]-b[1]
		bc[2] = c[2]-b[2]

		local dot = ab[1] * bc[1] + ab[2] * bc[2]
		local magA = math.sqrt(ab[1] * ab[1] + ab[2] * ab[2])
		local magB = math.sqrt(bc[1] * bc[1] + bc[2] * bc[2])
		local angle = math.acos(dot / (magA * magB))
		return angle < thresholdAngle
	end
end

function PolyDecomp.sqdist(a, b)
	local dx = b[1] - a[1]
	local dy = b[2] - a[2]
	return dx * dx + dy * dy
end

--[[
 * Get a vertex at position i. It does not matter if i is out of bounds, this function will just cycle.
 * @method at
 * @param  {Number} i
 * @return {Array}
]]--

function PolyDecomp.polygonAt(polygon, i)
	local n = #polygon

	-- return polygon[i < 0 and i % s + s or i % s]
	-- return polygon[i < 1 and i % s + s or i % s]
	return polygon[i % n ~= 0 and i % n or n]
end

--[[
 * Clear the polygon data
 * @method clear
 * @return {Array}
]]--
function PolyDecomp.polygonClear(polygon)
	for i=1, #polygon do
		polygon[i] = nil
	end
end

--[[
 * Append points "from" to "to"-1 from an other polygon "poly" onto this one.
 * @method append
 * @param {Polygon} poly The polygon to get points from.
 * @param {Number}  from The vertex index in "poly".
 * @param {Number}  to The end vertex index in "poly". Note that this vertex is NOT included when appending.
 * @return {Array}
]]--

function PolyDecomp.polygonAppend(polygon, poly, from, to)
	-- print('polygonAppend', from, to)
	for i=from, to do
		table.insert(polygon, poly[i])
	end
end

--[[
 * Make sure that the polygon vertices are ordered counter-clockwise.
 * @method makeCCW
]]--

function PolyDecomp.polygonMakeCCW(polygon)

	local br = 1
	local v = polygon

	-- find bottom right point
	for i = 2, #polygon do
		if (v[i][2] < v[br][2] or (
			v[i][2] == v[br][2] and v[i][1] > v[br][1]
		)) then
			br = i
		end
	end

	-- reverse poly if clockwise

	if (not PolyDecomp.isLeft(PolyDecomp.polygonAt(polygon, br - 1), PolyDecomp.polygonAt(polygon, br), PolyDecomp.polygonAt(polygon, br + 1))) then
		PolyDecomp.polygonReverse(polygon)
		return true
	else
		return false
	end
end

--[[
 * Reverse the vertices in the polygon
 * @method reverse
]]--

function PolyDecomp.polygonReverse(polygon)
	local tmp = {}
	local n = #polygon

	for i=1, n do
		table.insert(tmp, table.remove(polygon))
	end

	for i=1, n do
		polygon[i] = tmp[i]
	end

end

--[[
 * Check if a point in the polygon is a reflex point
 * @method isReflex
 * @param  {Number}  i
 * @return {Boolean}
]]--

function PolyDecomp.polygonIsReflex(polygon, i)

	return PolyDecomp.isRight(
		PolyDecomp.polygonAt(polygon, i - 1),
		PolyDecomp.polygonAt(polygon, i),
		PolyDecomp.polygonAt(polygon, i + 1))
end



--[[
 * Check if two vertices in the polygon can see each other
 * @method canSee
 * @param  {Number} a Vertex index 1
 * @param  {Number} b Vertex index 2
 * @return {Boolean}
]]--

function PolyDecomp.polygonCanSee(polygon, a, b)

	local l1=tmpLine1
	local l2=tmpLine2
	local p,
		dist

	if (PolyDecomp.isLeftOn(
		PolyDecomp.polygonAt(polygon, a + 1),
		PolyDecomp.polygonAt(polygon, a),
		PolyDecomp.polygonAt(polygon, b)
	) and PolyDecomp.isRightOn(
		PolyDecomp.polygonAt(polygon, a - 1),
		PolyDecomp.polygonAt(polygon, a),
		PolyDecomp.polygonAt(polygon, b))) then

		return false

	end

	dist = PolyDecomp.sqdist(PolyDecomp.polygonAt(polygon, a), PolyDecomp.polygonAt(polygon, b))

	-- for each edge
	for i = 1, #polygon do
		repeat
			-- ignore incident edges
			if ((i + 1) % #polygon == a or i == a) then
				break
			end

			-- if diag intersects an edge
			if (PolyDecomp.isLeftOn(
				PolyDecomp.polygonAt(polygon, a),
				PolyDecomp.polygonAt(polygon, b),
				PolyDecomp.polygonAt(polygon, i + 1)
			) and PolyDecomp.isRightOn(
				PolyDecomp.polygonAt(polygon, a),
				PolyDecomp.polygonAt(polygon, b),
				PolyDecomp.polygonAt(polygon, i))) then

				l1[1] = PolyDecomp.polygonAt(polygon, a)
				l1[2] = PolyDecomp.polygonAt(polygon, b)
				l2[1] = PolyDecomp.polygonAt(polygon, i)
				l2[2] = PolyDecomp.polygonAt(polygon, i + 1)

				p = PolyDecomp.lineInt(l1, l2)

				-- if edge is blocking visibility to b
				if (PolyDecomp.sqdist(PolyDecomp.polygonAt(polygon, a), p) < dist) then
					return false
				end
			end
		break
		until true
	end

	return true
end

--[[
 * Check if two vertices in the polygon can see each other
 * @method canSee2
 * @param  {Number} a Vertex index 1
 * @param  {Number} b Vertex index 2
 * @return {Boolean}
]]--
function PolyDecomp.polygonCanSee2(polygon, a, b)
	-- for each edge
	-- print('PolyDecomp.polygonCanSee2')
	local n = #polygon
	for i = 1, n do
		repeat
			-- ignore incident edges
			local x = (i+1) % n
			x = x ~= 0 and x or n

			if (i == a or i == b or x == a or x == b) then
				break
			end

			if( PolyDecomp.lineSegmentsIntersect(PolyDecomp.polygonAt(polygon, a), PolyDecomp.polygonAt(polygon, b), PolyDecomp.polygonAt(polygon, i), PolyDecomp.polygonAt(polygon, i+1)) ) then
				return false
			end

		break
		until true
	end

	return true
end

--[[
 * Copy the polygon from vertex i to vertex j.
 * @method copy
 * @param  {Number} i
 * @param  {Number} j
 * @param  {Polygon} [targetPoly]   Optional target polygon to save in.
 * @return {Polygon}				The resulting copy.
]]--
function PolyDecomp.polygonCopy(polygon, i, j, targetPoly)

	local p = targetPoly or {}

	PolyDecomp.polygonClear(p)

	if (i < j) then
		-- Insert all vertices from i to j

		for k=i,j do
			table.insert(p, polygon[k])
		end

	else

		-- Insert vertices 0 to j
		for k=1, j do
			table.insert(p, polygon[k])
		end

		-- Insert vertices i to end
		for k=i, #polygon do
			table.insert(p, polygon[k])
		end
	end

	return p
end

--[[
 * PolyDecomposes the polygon into convex pieces. Returns a list of edges [[p1,p2],[p2,p3],...] that cuts the polygon.
 * Note that this algorithm has complexity O(N^4) and will be very slow for polygons with many vertices.
 * @method getCutEdges
 * @return {Array}
]]--

function PolyDecomp.polygonGetCutEdges(polygon)

	local min = {}
	local tmp1 = {}
	local tmp2 = {}
	local tmpPoly = {}
	local nDiags = math.huge
	-- local n = #polygon

	for i = 1, #polygon do
		if (PolyDecomp.polygonIsReflex(polygon, i)) then
			for j = 1, #polygon do
				if (PolyDecomp.polygonCanSee(polygon, i, j)) then

					tmp1 = PolyDecomp.polygonGetCutEdges(PolyDecomp.polygonCopy(polygon, i, j, tmpPoly))
					tmp2 = PolyDecomp.polygonGetCutEdges(PolyDecomp.polygonCopy(polygon, j, i, tmpPoly))

					for k=1, #tmp2 do
						table.insert(tmp1, tmp2[k])
					end

					if (#tmp1 < nDiags) then
						min = tmp1
						nDiags = #tmp1
						table.insert(min, {
							PolyDecomp.polygonAt(polygon, i),
							PolyDecomp.polygonAt(polygon, j)
						})

					end
				end
			end
		end
	end

	return min
end

--[[
 * PolyDecomposes the polygon into one or more convex sub-Polygons.
 * @method PolyDecomp
 * @return {Array} An array or Polygon objects.
]]--

function PolyDecomp.polygonDecomp(polygon)

	local edges = PolyDecomp.polygonGetCutEdges(polygon)

	if(#edges > 0) then
		return PolyDecomp.polygonSlice(polygon, edges)
	else
		return {polygon}
	end
end

--[[
 * Slices the polygon given one or more cut edges. If given one, this function will return two polygons (false on failure). If many, an array of polygons.
 * @method slice
 * @param {Array} cutEdges A list of edges, as returned by .getCutEdges()
 * @return {Array}
]]--

function PolyDecomp.polygonSlice(polygon, cutEdges)

	if (#cutEdges == 0) then
		return {polygon}
	end

	if(type(cutEdges) == 'table' and #cutEdges and type(cutEdges[1]) == 'table' and #cutEdges[1] == 2 and type(cutEdges[1][1]) == 'table') then

		local polys = {polygon}

		for i=1, #cutEdges do

			local cutEdge = cutEdges[i]

			-- Cut all polys

			for j=1, #polys do

				local poly = polys[j]
				local result = PolyDecomp.polygonSlice(poly, cutEdge)

				if (result) then
					-- Found poly! Cut and quit
					table.remove(polys, j)
					table.insert(polys, result[1])
					table.insert(polys, result[2])
					break
				end
			end
		end

		return polys
	else

		-- Was given one edge
		local cutEdge = cutEdges
		local i = table.indexof(polygon, cutEdge[1])
		local j = table.indexof(polygon, cutEdge[2])

		if (i and j) then
			return {
					PolyDecomp.polygonCopy(polygon, i, j),
					PolyDecomp.polygonCopy(polygon, j, i)
				}
		else
			return false
		end
	end
end

--[[
 * Checks that the line segments of this polygon do not intersect each other.
 * @method isSimple
 * @param  {Array} path An array of vertices e.g. [[0,0],[0,1],...]
 * @return {Boolean}
 * @todo Should it check all segments with all others?
]]--
function PolyDecomp.polygonIsSimple(polygon)

	local path = polygon
	local i

	-- Check
	for i = 1, #path - 1 do

		for j = 1, i - 2 do
			if(PolyDecomp.lineSegmentsIntersect(path[i], path[i+1], path[j], path[j+1] )) then
				return false
			end
		end
	end

	-- Check the segment between the last and the first point to all others

	for i = 2, #path - 2 do
		if(PolyDecomp.lineSegmentsIntersect(path[1], path[#path], path[i], path[i+1] )) then
			return false
		end
	end

	return true
end

function PolyDecomp.getIntersectionPoint(p1, p2, q1, q2, delta)

	delta = delta or 0
	local a1 = p2[2] - p1[2]
	local b1 = p1[1] - p2[1]
	local c1 = (a1 * p1[1]) + (b1 * p1[2])
	local a2 = q2[2] - q1[2]
	local b2 = q1[1] - q2[1]
	local c2 = (a2 * q1[1]) + (b2 * q1[2])
	local det = (a1 * b2) - (a2 * b1)

	if( not PolyDecomp.scalar_eq(det, 0, delta)) then
		return {
				((b2 * c1) - (b1 * c2)) / det,
				((a1 * c2) - (a2 * c1)) / det
			}
	else
		return {0, 0}
	end
end

--[[
 * Quickly PolyDecompose the Polygon into convex sub-polygons.
 * @method quickPolyDecomp
 * @param  {Array} result
 * @param  {Array} [reflexVertices]
 * @param  {Array} [steinerPoints]
 * @param  {Number} [delta]
 * @param  {Number} [maxlevel]
 * @param  {Number} [level]
 * @return {Array}
]]--

function PolyDecomp.polygonQuickDecomp(polygon, result, reflexVertices, steinerPoints, delta, maxlevel, level)

	maxlevel = maxlevel or 100
	level = level or 0
	delta = delta or 25
	result = type(result) ~= 'nil' and result or {}
	reflexVertices = reflexVertices or {}
	steinerPoints = steinerPoints or {}

	local upperInt = {0,0}
	local lowerInt = {0,0}
	local p = {0,0} -- Points

	local upperDist = 0
	local lowerDist = 0
	local d = 0
	local closestDist = 0 -- scalars
	local upperIndex = 0
	local lowerIndex = 0
	local closestIndex = 0 -- Integers
	local lowerPoly = {}
	local upperPoly = {} -- polygons
	local poly = polygon
	local v = polygon

	if(#v < 3) then
		return result
	end

	level += 1

	if(level > maxlevel) then
		print('PolyDecomp:quickPolyDecomp: max level ('.. maxlevel ..') reached.')
		return result
	end

	for i = 1, #polygon do

		if (PolyDecomp.polygonIsReflex(poly, i)) then

			table.insert(reflexVertices, poly[i])

			upperDist = math.huge
			lowerDist = math.huge


			for j = 1, #polygon do

				-- if line intersects with an edge
				if (PolyDecomp.isLeft(PolyDecomp.polygonAt(poly, i - 1), PolyDecomp.polygonAt(poly, i), PolyDecomp.polygonAt(poly, j)) and PolyDecomp.isRightOn(PolyDecomp.polygonAt(poly, i - 1), PolyDecomp.polygonAt(poly, i), PolyDecomp.polygonAt(poly, j - 1))) then

					p = PolyDecomp.getIntersectionPoint(PolyDecomp.polygonAt(poly, i - 1), PolyDecomp.polygonAt(poly, i), PolyDecomp.polygonAt(poly, j), PolyDecomp.polygonAt(poly, j - 1)) -- find the point of intersection

					if (PolyDecomp.isRight(PolyDecomp.polygonAt(poly, i + 1), PolyDecomp.polygonAt(poly, i), p)) then -- make sure it's inside the poly

						d = PolyDecomp.sqdist(poly[i], p)
						if (d < lowerDist) then -- keep only the closest intersection
							lowerDist = d
							lowerInt = p
							lowerIndex = j
						end
					end
				end

				if (PolyDecomp.isLeft(PolyDecomp.polygonAt(poly, i + 1), PolyDecomp.polygonAt(poly, i), PolyDecomp.polygonAt(poly, j + 1)) and PolyDecomp.isRightOn(PolyDecomp.polygonAt(poly, i + 1), PolyDecomp.polygonAt(poly, i), PolyDecomp.polygonAt(poly, j))) then

					p = PolyDecomp.getIntersectionPoint(PolyDecomp.polygonAt(poly, i + 1), PolyDecomp.polygonAt(poly, i), PolyDecomp.polygonAt(poly, j), PolyDecomp.polygonAt(poly, j + 1))

					if (PolyDecomp.isLeft(PolyDecomp.polygonAt(poly, i - 1), PolyDecomp.polygonAt(poly, i), p)) then

						d = PolyDecomp.sqdist(poly[i], p)

						if (d < upperDist) then
							upperDist = d
							upperInt = p
							upperIndex = j
						end
					end
				end
			end

			-- if there are no vertices to connect to, choose a point in the middle
			local x = (upperIndex+1) % #polygon
			x = x ~= 0 and x or #polygon

			if (lowerIndex == x) then

				p[1] = (lowerInt[1] + upperInt[1]) / 2
				p[2] = (lowerInt[2] + upperInt[2]) / 2

				table.insert(steinerPoints, p)

				if (i < upperIndex) then

					PolyDecomp.polygonAppend(lowerPoly, poly, i, upperIndex)

					table.insert(lowerPoly, p)
					table.insert(upperPoly, p)

					-- if (lowerIndex ~= 0) then
					if (lowerIndex ~= 1) then
						PolyDecomp.polygonAppend(upperPoly, poly, lowerIndex, #poly)
					end

					PolyDecomp.polygonAppend(upperPoly, poly, 1, i)
				else

					if (i ~= 1) then
						PolyDecomp.polygonAppend(lowerPoly, poly, i, #poly)
					end

					PolyDecomp.polygonAppend(lowerPoly, poly, 1, upperIndex)
					table.insert(lowerPoly, p)
					table.insert(upperPoly, p)
					PolyDecomp.polygonAppend(upperPoly, poly, lowerIndex, i)
				end
			else
				-- connect to the closest point within the triangle

				if (lowerIndex > upperIndex) then
					upperIndex += #polygon
				end

				closestDist = math.huge

				if(upperIndex < lowerIndex) then
					return result
				end

				for j = lowerIndex, upperIndex do

					if (
						PolyDecomp.isLeftOn(PolyDecomp.polygonAt(poly, i - 1), PolyDecomp.polygonAt(poly, i), PolyDecomp.polygonAt(poly, j)) and
						PolyDecomp.isRightOn(PolyDecomp.polygonAt(poly, i + 1), PolyDecomp.polygonAt(poly, i), PolyDecomp.polygonAt(poly, j))
					) then
						d = PolyDecomp.sqdist(PolyDecomp.polygonAt(poly, i), PolyDecomp.polygonAt(poly, j))

						if (d < closestDist and PolyDecomp.polygonCanSee2(poly, i, j)) then

							closestDist = d
							closestIndex = j % #polygon
							closestIndex = 	closestIndex ~= 0 and closestIndex or #polygon
						end
					end
				end

				if (i < closestIndex) then

					PolyDecomp.polygonAppend(lowerPoly, poly, i, closestIndex)

					if (closestIndex ~= 1) then
						PolyDecomp.polygonAppend(upperPoly, poly, closestIndex, #v)
					end

					PolyDecomp.polygonAppend(upperPoly, poly, 1, i)
				else

					if (i ~= 1) then
						PolyDecomp.polygonAppend(lowerPoly, poly, i, #v)
					end

					PolyDecomp.polygonAppend(lowerPoly, poly, 1, closestIndex)
					PolyDecomp.polygonAppend(upperPoly, poly, closestIndex, i)
				end
			end

			-- solve smallest poly first

			if (#lowerPoly < #upperPoly) then
				PolyDecomp.polygonQuickDecomp(lowerPoly, result, reflexVertices, steinerPoints, delta, maxlevel, level)
				PolyDecomp.polygonQuickDecomp(upperPoly, result, reflexVertices, steinerPoints, delta, maxlevel, level)
			else
				PolyDecomp.polygonQuickDecomp(upperPoly, result, reflexVertices, steinerPoints, delta, maxlevel, level)
				PolyDecomp.polygonQuickDecomp(lowerPoly, result, reflexVertices, steinerPoints, delta, maxlevel, level)
			end

			return result
		end
	end

	table.insert(result, polygon)

	return result
end

--[[
 * Remove collinear points in the polygon.
 * @method removeCollinearPoints
 * @param  {Number} [precision] The threshold angle to use when determining whether two edges are collinear. Use zero for finest precision.
 * @return {Number}		   The number of points removed
]]--

function PolyDecomp.polygonRemoveCollinearPoints(polygon, precision)

	local num = 0
	local min = #polygon > 3
	for i=#polygon, min and 1, -1 do
		if(PolyDecomp.collinear(PolyDecomp.polygonAt(polygon, i-1), PolyDecomp.polygonAt(polygon, i), PolyDecomp.polygonAt(polygon, i+1),precision)) then
			-- Remove the middle point
			table.remove(polygon, i % #polygon)
			num += 1
		end
	end
	return num
end

--[[
 * Remove duplicate points in the polygon.
 * @method removeDuplicatePoints
 * @param  {Number} [precision] The threshold to use when determining whether two points are the same. Use zero for best precision.
]]--

function PolyDecomp.polygonRemoveDuplicatePoints(polygon, precision)

	for i=#polygon, 2, -1 do
		local pi = polygon[i]
		for j=i-1, 1, -1 do
			repeat
				if(PolyDecomp.points_eq(pi, polygon[j], precision)) then
					table.remove(polygon, i)
					break
				end
			break
			until true
		end
	end
end

--[[
 * Check if two scalars are equal
 * @static
 * @method eq
 * @param  {Number} a
 * @param  {Number} b
 * @param  {Number} [precision]
 * @return {Boolean}
]]--
function PolyDecomp.scalar_eq(a, b, precision)
	precision = precision or 0
	return math.abs(a-b) <= precision
end

--[[
 * Check if two points are equal
 * @static
 * @method points_eq
 * @param  {Array} a
 * @param  {Array} b
 * @param  {Number} [precision]
 * @return {Boolean}
]]--

function PolyDecomp.points_eq(a,b,precision)
	return PolyDecomp.scalar_eq(a[1],b[1],precision) and PolyDecomp.scalar_eq(a[2],b[2],precision)
end

-- module.exports = {
-- 	PolyDecomp: polygonDecomp,
-- 	quickPolyDecomp: polygonQuickDecomp,
-- 	isSimple: polygonIsSimple,
-- 	removeCollinearPoints: polygonRemoveCollinearPoints,
-- 	removeDuplicatePoints: polygonRemoveDuplicatePoints,
-- 	makeCCW: polygonMakeCCW
-- }

PolyDecomp.decomp = PolyDecomp.polygonDecomp
PolyDecomp.quickDecomp = PolyDecomp.polygonQuickDecomp
PolyDecomp.isSimple = PolyDecomp.polygonIsSimple
PolyDecomp.removeCollinearPoints = PolyDecomp.polygonRemoveCollinearPoints
PolyDecomp.removeDuplicatePoints = PolyDecomp.polygonRemoveDuplicatePoints
PolyDecomp.makeCCW = PolyDecomp.polygonMakeCCW
