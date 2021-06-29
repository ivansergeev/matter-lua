--[[
* The `Matter.Axes` module contains methods for creating and manipulating sets of axes.
*
* @class Axes
]]--

import 'matter/geometry/Vector'
import 'matter/core/Common'

Axes = {}
Axes.__index = Axes


--[[
 * Creates a new set of axes from the given vertices.
 * @method fromVertices
 * @param {vertices} vertices
 * @return {axes} A new axes from the given vertices
 ]]--

function Axes.fromVertices(vertices)

	local axes = {}
	local n = #vertices

	-- find the unique axes, using edge normal gradients
	for i = 1, n do

		local j = (i + 1) % n
		j = j ~= 0 and j or n

		local normal = Vector.normalise({
				x = vertices[j].y - vertices[i].y,
				y = vertices[i].x - vertices[j].x
			})

		local gradient = (normal.y == 0) and math.huge or (normal.x / normal.y)

		-- limit precision
		gradient = gradient == -0.0 and 0.0 or gradient
		gradient = string.format('%.3f', gradient)

		axes[gradient] = normal
	end

	return Common.values(axes)
end

--[[
 * Rotates a set of axes by the given angle.
 * @method rotate
 * @param {axes} axes
 * @param {number} angle
 ]]--

function Axes.rotate(axes, angle)

	if (angle == 0) then
		return
	end

	local cos, sin = math.cos(angle), math.sin(angle)
	local n = #axes

	for i = 1, n do
		local axis = axes[i]
		local xx = axis.x * cos - axis.y * sin

		axis.y = axis.x * sin + axis.y * cos
		axis.x = xx
	end
end

