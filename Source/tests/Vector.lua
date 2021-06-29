-- Matter
import 'matter/matter'

local v1 = {x = 123, y = 456 }
local v2 = {x = -43, y = -21 }
local p = {x = 200, y = 120}

print('Vector.create')
printTable(Vector.create(v1.x, v1.y))
printTable(Vector.create(v2.x, v2.y))

print('Vector.clone')
printTable(Vector.clone(v1))

print('Vector.magnitude')
printTable(Vector.magnitude(v2))
print(vectorMagnitude(v2.x, v2.y))

print('Vector.magnitudeSquared')
print(Vector.magnitudeSquared(v1))
-- print(vectorMagnitudeSquared(v1.x, v1.y))

print('Vector.rotate')
printTable(Vector.rotate(v1, -17))
print(vectorRotate(v1.x, v1.y, -17))

printTable(Vector.rotate(v1, 45, {}))
print(vectorRotate(v1.x, v1.y, 45, {}))

print('Vector.rotateAbout')
printTable(Vector.rotateAbout(v1, -17, p))
printTable(Vector.rotateAbout(v1, 45, p, {}))

print('Vector.normalise')
printTable(Vector.normalise(v1))
print(vectorNormalise(v1.x, v1.y))

printTable(Vector.normalise(v2))
print(vectorNormalise(v2.x, v2.y))


print('Vector.dot')
printTable(Vector.dot(v1, v2))
print(vectorDot(v1.x, v1.y, v2.x, v2.y))

print('Vector.cross')
print(Vector.cross(v1, v2))
print(vectorCross(v1.x, v1.y, v2.x, v2.y))

print('Vector.cross3')
printTable(Vector.cross3(v1, v2, p))
print(vectorCross3(v1.x, v1.y, v2.x, v2.y, p.x, p.y))

print('Vector.add')
printTable(Vector.add(v1, v2))
print(vectorAdd(v1.x, v1.y, v2.x, v2.y))

print('Vector.sub')
printTable(Vector.sub(v1, v2))
print(vectorSub(v1.x, v1.y, v2.x, v2.y))

print('Vector.mult')
printTable(Vector.mult(v1, 1))
print(vectorMult(v1.x, v1.y, 1))

print('Vector.div')
printTable(Vector.div(v1, 2))
printTable(vectorDiv(v1.x, v1.y, 2))

print('Vector.perp')
printTable(Vector.perp(v1, true))
print(vectorPerp(v1.x, v1.y, true))

printTable(Vector.perp(v1, false))
print(vectorPerp(v1.x, v1.y, false))

print('Vector.neg')
printTable(Vector.neg(v1))
print(vectorNeg(v1.x, v1.y))
printTable(Vector.neg(v2))
print(vectorNeg(v2.x, v2.y))

print('Vector.angle')
print(Vector.angle(v1, v2))
print(vectorAngle(v1.x, v1.y, v2.x, v2.y))
