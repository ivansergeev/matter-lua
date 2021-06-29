-- Matter
import 'matter/matter'

local path = '110.5,80.5 154.5,39.5 238.5,39.5 269.5,120.5 194.5,204.5 '
path = '172.5, 43.61111, 187.5,43.61111, 187.5,58.61111, 172.5,58.61111'

print('Vertices.fromPath')
local v = Vertices.fromPath(path, {})
printTable(v)

print('Axes.fromVertices')
a1 = Axes.fromVertices(v)
printTable(a1)

print('Axes.rotate')
Axes.rotate(a1, 45)
printTable(a1)


-- {
-- 			[body] = reference: /,
-- 			[index] = 1,
-- 			[isInternal] = false,
-- 			[x] = 172.5,
-- 			[y] = 43.61111,
-- 		},
-- 		{
-- 			[body] = reference: /,
-- 			[index] = 2,
-- 			[isInternal] = false,
-- 			[x] = 187.5,
-- 			[y] = 43.61111,
-- 		},
-- 		{
-- 			[body] = reference: /,
-- 			[index] = 3,
-- 			[isInternal] = false,
-- 			[x] = 187.5,
-- 			[y] = 58.61111,
-- 		},
-- 		{
-- 			[body] = reference: /,
-- 			[index] = 4,
-- 			[isInternal] = false,
-- 			[x] = 172.5,
-- 			[y] = 58.61111,
-- 		},

	-- [axes] = {
	-- 	{
	-- 		[x] = 0.0,
	-- 		[y] = -1.0,
	-- 	},
	-- 	{
	-- 		[x] = -1.0,
	-- 		[y] = 0.0,
	-- 	},
	-- 	{
	-- 		[x] = 0.0,
	-- 		[y] = 1.0,
	-- 	},
	-- },