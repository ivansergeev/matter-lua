-- Matter
import 'utils/Test'
import 'matter/libs/PolyDecomp'

local polyDecomp = PolyDecomp

local concave = {
	{-1, 1},
	{-1, 0},
	{1, 0},
	{1, 1},
	{0.5, 0.5}
}

local circle = {}
local n = 10

for i=1, n do
	local angle = 2 * math.pi/n * i
	table.insert(circle, {math.cos(angle), math.sin(angle)})
end

local path = {
	{9.5,72.5},
	{118.5,148.5},
	{288.5,163.5},
	{388.5,97.5},
	{386.5,231.5},
	{12.5,229.5},
}

local task1 = {

	decomp = function(test)
		local circleConvexes = polyDecomp.decomp(circle)
		test:equal(#circleConvexes, 1)
		-- printTable(circleConvexes)
		local concaveConvexes = polyDecomp.decomp(concave)
		test:equal(#concaveConvexes, 2)
		-- printTable(concaveConvexes)

		local pathConvexes = polyDecomp.decomp(path)
		test:equal(#pathConvexes, 3)
		-- printTable(pathConvexes)

		test:done()
	end,

	isSimple = function(test)
		local notSimple = {
			{-1,-1},
			{0, 0},
			{1, 1},
			{0, 2},
			{-1, 1},
			{0, 0},
			{1,-1}
		}

		test:ok(polyDecomp.isSimple(concave))
		test:ok(polyDecomp.isSimple(circle))
		test:ok(not polyDecomp.isSimple(notSimple))
		test:done()
	end,

	quickDecomp = function(test)
		local result = polyDecomp.quickDecomp(circle)
		-- printTable(result)
		test:equal(#result, 1)
		local convexResult = polyDecomp.quickDecomp(concave)
		test:equal(#convexResult, 2)
		-- printTable(convexResult)
		local pathConvexes = polyDecomp.quickDecomp(path)
		test:equal(#pathConvexes, 3)
		-- printTable(pathConvexes)

		test:done()
	end,

	removeDuplicatePoints = function(test)

		local data = {
			{0,0},
			{1,1},
			{2,2},
			{0,0}
		}

		polyDecomp.removeDuplicatePoints(data)
		test:equal(#data, 3)
		-- printTable(data)
		local data2 = {
			{0,0},
			{1,1},
			{2,2},
			{1,1},
			{0,0},
			{2,2}
		}
			polyDecomp.removeDuplicatePoints(data2)
			test:equal(#data2, 3)
			-- printTable(data2)
			test:done()
	end,

	 quickDecompExtraVisibilityTestFix = function(test)

		-- This test checks that this bug is fixed: https://github.com/schteppe/poly-decomp.js/issues/8

		local path = {
			{0,-134},
			{50,-139},
			{60,-215},
			{70,-6},
			{80,-236},
			{110,-120},
			{110,0},
			{0,0}
		}
		for k, v in pairs(path) do
			path[k] = {
				2*v[1]+100,
				1*v[2]+500
			}
		end

		polyDecomp.makeCCW(path)
		-- printTable(path)
		local polys = polyDecomp.quickDecomp(path)
		test:equal(#polys, 3)

		-- printTable(polys)
		path = {
			{0,-134},
			{50,-139},
			{60,-215},
			{70,-6},
			{80,-236},
			{110,-120},
			{110,0},
			{0,0}
		}

		for k, v in pairs(path) do
			path[k] = {
				3*v[1]+100,
				1*v[2]+500
			}
		end

		polyDecomp.makeCCW(path)

		local polys = polyDecomp.quickDecomp(path)

		test:equal(#polys, 3)

		path = {
			{0,-134},
			{50,-139},
			{60,-215},
			{70,-6},
			{80,-236},
			{110,-120},
			{110,0},
			{0,0}
		}

		for k, v in pairs(path) do
			path[k] = {
				-3*v[1],
				-v[2]
			}
		end

		polyDecomp.makeCCW(path)

		local polys = polyDecomp.quickDecomp(path)
		test:equal(#polys, 3)

		path = {{331,384},{285,361},{238,386},{283,408},{191,469},{213,372},{298,314},{342,340}}

		polyDecomp.makeCCW(path)
		local polys = polyDecomp.quickDecomp(path)
		test:equal(#polys, 3)

		test:done()
	end
}

local task2 = {

	quickDecomp = function(test)
		local result = polyDecomp.quickDecomp(circle)
		-- printTable(result)
		test:equal(#result, 1)
		local convexResult = polyDecomp.quickDecomp(concave)
		test:equal(#convexResult, 2)
		-- printTable(convexResult)
		local pathConvexes = polyDecomp.quickDecomp(path)
		test:equal(#pathConvexes, 3)
		-- printTable(pathConvexes)

		test:done()
	end
}

for name, func in pairs(task2) do
	local test = Test:new(name)
	func(test)
end
