-- Matter
import 'matter/matter'


local path = '110.5,80.5 154.5,39.5 238.5,39.5 269.5,120.5 194.5,204.5 '
local path2 = '2.5,140.5 23.5,132.5 40.5,140.5 58.5,164.5 84.5,153.5 114.5,162.5 127.5,172.5 159.5,172.5 167.5,161.5 189.5,150.5 222.5,170.5 237.5,192.5 263.5,192.5 277.5,178.5 283.5,158.5 307.5,139.5 329.5,149.5 355.5,136.5 387.5,126.5 394.5,125.5 395.5,235.5 2.5,235.5 '

print('Vertices.fromPath')
local v = Vertices.fromPath(path2, {})

printTable(v)

print('Vertices.centre')
v1 = Vertices.centre(v)
printTable(v1)

print('Vertices.mean')
printTable(Vertices.mean(v))

print('Vertices.area')
v3 = Vertices.area(v)
printTable(v3)

print('Vertices.area')
v3_1 = Vertices.area(v, true)
printTable(v3_1)

print('Vertices.inertia')
v4 = Vertices.inertia(v, 1)
printTable(v4)

print('Vertices.translate')
v5 = Vertices.translate(v, {x = 1, y = 1})
printTable(v5)

print('Vertices.translate')
v5_1 = Vertices.translate(v, {x = -1, y = -1}, 1)
printTable(v5_1)

print('Vertices.rotate')
v6 = Vertices.rotate(v, 45, {x = 1, y = 1})
printTable(v6)

print('Vertices.contains')
v7 = Vertices.contains(v, {x = 10, y = 10})
printTable(v7)

print('Vertices.scale')
v8 = Vertices.scale(v, 0.5, 0.5, {x = 10, y = 10})
printTable(v8)

print('Vertices.chamfer')
v9 = Vertices.chamfer(v, 10)
printTable(v9)

print('Vertices.clockwiseSort')
v10 = Vertices.clockwiseSort(v)
printTable(v10)

print('Vertices.isConvex')
v11 = Vertices.isConvex(v)
printTable(v11)

-- !!! Check with original
print('Vertices.hull')
v12 = Vertices.hull(v)
printTable(v12)

print('----')
local p2 = 'L 14.712 2.926 L 12.472 8.334 L 8.334 12.472 L 2.926 14.712 L -2.926 14.712 L -8.334 12.472 L -12.472 8.334 L -14.712 2.926 L -14.712 -2.926 L -12.472 -8.334 L -8.334 -12.472 L -2.926 -14.712 L 2.926 -14.712 L 8.334 -12.472 L 12.472 -8.334 L 14.712 -2.926 '

local p2v = Vertices.fromPath(p2, {});
printTable(p2v);

