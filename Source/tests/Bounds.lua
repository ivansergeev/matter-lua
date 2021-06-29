-- Matter
import 'matter/matter'

local path = '110.5,80.5 154.5,39.5 238.5,39.5 269.5,120.5 194.5,204.5 '
local path2 = '110.5,80.5 150.5,30.5 240.5,39.5 169.5,170.5 194.5,204.5 '
local p = {x = 200, y = 120}

print('Vertices.fromPath')
local v = Vertices.fromPath(path, {})
local v2 = Vertices.fromPath(path2)
printTable(v)

print('Bounds.create')
local b1 = Bounds.create(v)
local b2 = Bounds.create(v2)
printTable(b1)

print('Bounds.update')
Bounds.update(b1, v2)
printTable(b1)

Bounds.update(b1, v2, {x = 3, y = 4})
printTable(b1)

print('Bounds.contains')
print(Bounds.contains(b1, p))
printTable(b1)
print(Bounds.contains(b1, {x = 1, y = 1}))
printTable(b1)

print('Bounds.overlaps')
printTable(Bounds.overlaps(b1, b2))

print('Bounds.translate')
Bounds.translate(b1, {x = -1, y = 1})
printTable(b1)

print('Bounds.shift')
Bounds.shift(b1, p)
printTable(b1)


