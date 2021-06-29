--[[
* The `Matter.Vector` module contains methods for creating and manipulating vectors.
* Vectors are the basis of all the geometry related operations in the engine.
* A `Matter.Vector` object is of the form `{ x: 0, y: 0 }`.
*
* See the included usage [examples](https:--github.com/liabru/matter-js/tree/master/examples).
*
* @class Vector
]]--

-- TODO: consider params for reusing vector objects

Vector = {}
Vector.__index = Vector


--[[
 * Creates a new vector.
 * @method create
 * @param {number} x
 * @param {number} y
 * @return {vector} A new vector
 ]]--
 
function Vector.create(x, y)
	return { x = x or 0, y = y or 0 }
end

--[[
 * Returns a new vector with `x` and `y` copied from the given `vector`.
 * @method clone
 * @param {vector} vector
 * @return {vector} A new cloned vector
 ]]--
 function Vector.clone(vector)
	return { x = vector.x, y = vector.y }
end

--[[
 * Returns the magnitude (length) of a vector.
 * @method magnitude
 * @param {vector} vector
 * @return {number} The magnitude of the vector
 ]]--
function Vector.magnitude(vector)
	return math.sqrt((vector.x * vector.x) + (vector.y * vector.y))
end

--[[
 * Returns the magnitude (length) of a vector (therefore saving a `sqrt` operation).
 * @method magnitudeSquared
 * @param {vector} vector
 * @return {number} The squared magnitude of the vector
 ]]--
function Vector.magnitudeSquared(vector)
	return (vector.x * vector.x) + (vector.y * vector.y)
end

--[[
 * Rotates the vector about (0, 0) by specified angle.
 * @method rotate
 * @param {vector} vector
 * @param {number} angle
 * @param {vector} [output]
 * @return {vector} The vector rotated about (0, 0)
 ]]--
function Vector.rotate(vector, angle, output)
	local cos, sin = math.cos(angle), math.sin(angle)
	local output = output or {x = 0, y = 0}

	output.y = vector.x * sin + vector.y * cos
	output.x = vector.x * cos - vector.y * sin
	
	return output
end

--[[
 * Rotates the vector about a specified point by specified angle.
 * @method rotateAbout
 * @param {vector} vector
 * @param {number} angle
 * @param {vector} point
 * @param {vector} [output]
 * @return {vector} A new vector rotated about the point
 ]]--
function Vector.rotateAbout(vector, angle, point, output)
	local cos, sin = math.cos(angle), math.sin(angle)
	local output = output or {x = 0, y = 0}

	output.y = point.y + ((vector.x - point.x) * sin + (vector.y - point.y) * cos)
	output.x = point.x + ((vector.x - point.x) * cos - (vector.y - point.y) * sin)
	return output
end

--[[
 * Normalises a vector (such that its magnitude is `1`).
 * @method normalise
 * @param {vector} vector
 * @return {vector} A new vector normalised
 ]]--
 
function Vector.normalise(vector)
	
	local magnitude = Vector.magnitude(vector)
	
	if (magnitude == 0) then
		return { x = 0, y = 0 }
	end
	
	return { x = vector.x / magnitude, y = vector.y / magnitude }
end

--[[
 * Returns the dot-product of two vectors.
 * @method dot
 * @param {vector} vectorA
 * @param {vector} vectorB
 * @return {number} The dot product of the two vectors
 ]]--
function Vector.dot(vectorA, vectorB)
	return (vectorA.x * vectorB.x) + (vectorA.y * vectorB.y)
end

--[[
 * Returns the cross-product of two vectors.
 * @method cross
 * @param {vector} vectorA
 * @param {vector} vectorB
 * @return {number} The cross product of the two vectors
 ]]--
function Vector.cross(vectorA, vectorB)
	return (vectorA.x * vectorB.y) - (vectorA.y * vectorB.x)
end

--[[
 * Returns the cross-product of three vectors.
 * @method cross3
 * @param {vector} vectorA
 * @param {vector} vectorB
 * @param {vector} vectorC
 * @return {number} The cross product of the three vectors
 ]]--
function Vector.cross3(vectorA, vectorB, vectorC)	
	return (vectorB.x - vectorA.x) * (vectorC.y - vectorA.y) - (vectorB.y - vectorA.y) * (vectorC.x - vectorA.x)
end

--[[
 * Adds the two vectors.
 * @method add
 * @param {vector} vectorA
 * @param {vector} vectorB
 * @param {vector} [output]
 * @return {vector} A new vector of vectorA and vectorB added
 ]]--
function Vector.add(vectorA, vectorB, output)
	local output = output or {x = 0, y = 0}
	output.x = vectorA.x + vectorB.x
	output.y = vectorA.y + vectorB.y
	return output
end

--[[
 * Subtracts the two vectors.
 * @method sub
 * @param {vector} vectorA
 * @param {vector} vectorB
 * @param {vector} [output]
 * @return {vector} A new vector of vectorA and vectorB subtracted
 ]]--
 
function Vector.sub(vectorA, vectorB, output)
	local output = output or {x = 0, y = 0}
	output.x = vectorA.x - vectorB.x
	output.y = vectorA.y - vectorB.y
	return output
end

--[[
 * Multiplies a vector and a scalar.
 * @method mult
 * @param {vector} vector
 * @param {number} scalar
 * @return {vector} A new vector multiplied by scalar
 ]]--
function Vector.mult(vector, scalar)
	return { x = vector.x * scalar, y = vector.y * scalar }
end

--[[
 * Divides a vector and a scalar.
 * @method div
 * @param {vector} vector
 * @param {number} scalar
 * @return {vector} A new vector divided by scalar
 ]]--
function Vector.div(vector, scalar)
	return { x = vector.x / scalar, y = vector.y / scalar }
end

--[[
 * Returns the perpendicular vector. Set `negate` to true for the perpendicular in the opposite direction.
 * @method perp
 * @param {vector} vector
 * @param {bool} [negate=false]
 * @return {vector} The perpendicular vector
 ]]--
function Vector.perp(vector, negate)
	
	negate = negate == true and -1 or 1
	
	return { x = negate * -vector.y, y = negate * vector.x }
end

--[[
 * Negates both components of a vector such that it points in the opposite direction.
 * @method neg
 * @param {vector} vector
 * @return {vector} The negated vector
 ]]--
function Vector.neg(vector)
	return { x = -vector.x, y = -vector.y }
end

--[[
 * Returns the angle between the vector `vectorB - vectorA` and the x-axis in radians.
 * @method angle
 * @param {vector} vectorA
 * @param {vector} vectorB
 * @return {number} The angle in radians
 ]]--
function Vector.angle(vectorA, vectorB)
	return math.atan2(vectorB.y - vectorA.y, vectorB.x - vectorA.x)
end

--[[
 * Temporary vector pool (not thread-safe).
 * @property _temp
 * @type {vector[]}
 * @private
 ]]--


Vector._temp = {
	Vector.create(), Vector.create(), 
	Vector.create(), Vector.create(), 
	Vector.create(), Vector.create()
}

-- Common functions

function vectorAdd(ax, ay, bx, by, output)
	if	output then
		output.x = ax + bx
		output.y = ay + by
		return output.x, output.y
	else
		return ax + bx, ay + by
	end
end

function vectorSub(ax, ay, bx, by, output)
	if 	output then
		output.x = ax - bx
		output.y = ay - by
		return output.x, output.y
	else
		return ax - bx, ay - by
	end	
end

function vectorCross(ax, ay, bx, by)
	return (ax * by) - (ay * bx)
end

function vectorCross3(ax, ay, bx, by, cx, cy)
	return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
end

function vectorDot(ax, ay, bx, by)
	return (ax * bx) + (ay * by)
end

function vectorMult(vx, vy, scalar)
	return vx * scalar, vy * scalar
end

function vectorPerp(vx, vy, negate)
	negate = negate == true and -1 or 1
	return negate * -vy, negate * vx
end

function vectorNeg(vx, vy)
	return -vx, -vy
end

function vectorRotate(vx, vy, angle, output)

	local cos, sin = math.cos(angle), math.sin(angle)
	
	if 	output then
		output.x = vx * cos - vy * sin
		output.y = vx * sin + vy * cos
		return output.x, output.y
	else
		return vx * cos - vy * sin, vx * sin + vy * cos
	end

end

-- optimise return
function vectorDiv(vx, vy, scalar)
	return { x = vx / scalar, y = vy / scalar }
end

function vectorNormalise(vx, vy)
	
	local magnitude = vectorMagnitude(vx, vy)
	
	if (magnitude == 0) then
		return 0, 0
	end
	
	return vx / magnitude, vy / magnitude
end

function vectorMagnitude(vx, vy)
	return math.sqrt((vx * vx) + (vy * vy))
end

function vectorAngle(ax, ay, bx, by)
	return math.atan2(by - ay, bx - ax)
end

