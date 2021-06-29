--[[
* The `Matter.Grid` module contains methods for creating and manipulating collision broadphase grid structures.
*
* @class Grid
]]--

import 'matter/collision/Pair'
import 'matter/collision/Detector'
import 'matter/core/Common'

Grid = {}
Grid.__index = Grid

--[[
 * Creates a new grid.
 * @method create
 * @param {} options
 * @return {grid} A new grid
 ]]--

Grid.create = function(options)

	local defaults = {
		controller = Grid,
		detector = Detector.collisions,
		buckets = {},
		pairs = {},
		pairsList = {},
		bucketWidth = 40,
		bucketHeight = 40,
	}

	return Common.extend(defaults, options)
end

--[[
 * The width of a single grid bucket.
 *
 * @property bucketWidth
 * @type number
 * @default 48
 ]]--

--[[
 * The height of a single grid bucket.
 *
 * @property bucketHeight
 * @type number
 * @default 48
 ]]--

--[[
 * Updates the grid.
 * @method update
 * @param {grid} grid
 * @param {body[]} bodies
 * @param {engine} engine
 * @param {boolean} forceUpdate
 ]]--

Grid.update = function(grid, bodies, engine, forceUpdate)

	-- print('Grid.update', #bodies)

	local col, row
	local world = engine.world
	local buckets = grid.buckets
	local gridChanged = false
	local n = #bodies

	-- forceUpdate = true

	local bucket,
		bucketId

	-- @if DEBUG
	-- local metrics = engine.metrics
	-- metrics.broadphaseTests = 0
	-- @endif

	for i = 1, n do
		repeat

			local body = bodies[i]

			if (body.isSleeping and not forceUpdate) then
				-- print('sleeping or not forceUpdate')
				break
			end

			-- don't update out of world bodies

			if (body.bounds.max.x < world.bounds.min.x or body.bounds.min.x > world.bounds.max.x
				or body.bounds.max.y < world.bounds.min.y or body.bounds.min.y > world.bounds.max.y) then
					-- print('Grid.update: out the world')
				break
			end

			local newRegion = Grid._getRegion(grid, body)

			if (not body.region or newRegion.id ~= body.region.id or forceUpdate) then

				-- @if DEBUG
				-- metrics.broadphaseTests += 1
				-- @endif

				if (not body.region or forceUpdate) then

					body.region = newRegion
				end

				local union = Grid._regionUnion(newRegion, body.region)

				for col = union.startCol, union.endCol do

					for row = union.startRow, union.endRow do

						bucketId = Grid._getBucketId(col, row)
						bucket = buckets[bucketId]

						local isInsideNewRegion = (col >= newRegion.startCol and col <= newRegion.endCol
												and row >= newRegion.startRow and row <= newRegion.endRow)

						local isInsideOldRegion = (col >= body.region.startCol and col <= body.region.endCol
												and row >= body.region.startRow and row <= body.region.endRow)


						-- remove from old region buckets

						if (not isInsideNewRegion
							and isInsideOldRegion
							and isInsideOldRegion
							and bucket) then
							-- print('clear bucket #', bucketId)
							Grid._bucketRemoveBody(grid, bucket, body)
						end

						-- add to new region buckets
						if (body.region == newRegion or (isInsideNewRegion and not isInsideOldRegion) or forceUpdate) then

							if (not bucket) then
								bucket = Grid._createBucket(buckets, bucketId)
							end

							Grid._bucketAddBody(grid, bucket, body)
						end
					end
				end

				-- set the new region
				body.region = newRegion

				-- flag changes so we can update pairs
				gridChanged = true
			end
		break
		until true
	end

	-- update pairs list only if pairs changed (i.e. a body changed region)
	if (gridChanged) then
		grid.pairsList = Grid._createActivePairsList(grid)
	end

end

--[[
 * Clears the grid.
 * @method clear
 * @param {grid} grid
 ]]--

function Grid.clear(grid)
	grid.buckets = {}
	grid.pairs = {}
	grid.pairsList = {}
end

--[[
 * Finds the union of two regions.
 * @method _regionUnion
 * @private
 * @param {} regionA
 * @param {} regionB
 * @return {} region
 ]]--

function Grid._regionUnion(regionA, regionB)

	local startCol = math.min(regionA.startCol, regionB.startCol)
	local endCol = math.max(regionA.endCol, regionB.endCol)
	local startRow = math.min(regionA.startRow, regionB.startRow)
	local endRow = math.max(regionA.endRow, regionB.endRow)

	return Grid._createRegion(startCol, endCol, startRow, endRow)
end

--[[
 * Gets the region a given body falls in for a given grid.
 * @method _getRegion
 * @private
 * @param {} grid
 * @param {} body
 * @return {} region
 ]]--

function Grid._getRegion(grid, body)

	-- print('Grid._getRegion')
	-- printTable(body.bounds)

	local bounds = body.bounds
	local startCol = math.floor(bounds.min.x / grid.bucketWidth)
	local endCol = math.floor(bounds.max.x / grid.bucketWidth)
	local startRow = math.floor(bounds.min.y / grid.bucketHeight)
	local endRow = math.floor(bounds.max.y / grid.bucketHeight)

	return Grid._createRegion(startCol, endCol, startRow, endRow)
end

--[[
 * Creates a region.
 * @method _createRegion
 * @private
 * @param {} startCol
 * @param {} endCol
 * @param {} startRow
 * @param {} endRow
 * @return {} region
 ]]--

function Grid._createRegion(startCol, endCol, startRow, endRow)
	return {
		id = startCol .. ',' .. endCol .. ',' .. startRow .. ',' .. endRow,
		startCol = startCol,
		endCol = endCol,
		startRow = startRow,
		endRow = endRow,
	}
end

--[[
 * Gets the bucket id at the given position.
 * @method _getBucketId
 * @private
 * @param {} column
 * @param {} row
 * @return {string} bucket id
 ]]--
function Grid._getBucketId(column, row)
	return 'C' .. column .. 'R' .. row
end

--[[
 * Creates a bucket.
 * @method _createBucket
 * @private
 * @param {} buckets
 * @param {} bucketId
 * @return {} bucket
 ]]--

function Grid._createBucket(buckets, bucketId)

	buckets[bucketId] = {}
	local bucket = buckets[bucketId]

	return bucket
end

--[[
 * Adds a body to a bucket.
 * @method _bucketAddBody
 * @private
 * @param {} grid
 * @param {} bucket
 * @param {} body
 ]]--

function Grid._bucketAddBody(grid, bucket, body)

	-- print('Grid._bucketAddBody', body.id, ' to bucket', #bucket)

	local n = #bucket

	-- add new pairs
	for i = 1, n do
		repeat
			local bodyB = bucket[i]

			if (body.id == bodyB.id or (body.isStatic and bodyB.isStatic)) then
				break
			end

			-- keep track of the number of buckets the pair exists in
			-- important for Grid.update to work
			local pairId = Pair.id(body, bodyB)
			local pair = grid.pairs[pairId]

			if (pair) then
				pair[3] += 1
			else
				grid.pairs[pairId] = {body, bodyB, 1}
			end
		break
		until true
	end

	-- add to bodies (after pairs, otherwise pairs with self)

	table.insert(bucket, body)
end

--[[
 * Removes a body from a bucket.
 * @method _bucketRemoveBody
 * @private
 * @param {} grid
 * @param {} bucket
 * @param {} body
 ]]--

function Grid._bucketRemoveBody(grid, bucket, body)
	-- remove from bucket

	table.remove(bucket, Common.indexOf(bucket, body))

	local n = #bucket

	-- update pair counts
	for i = 1, n do
		-- keep track of the number of buckets the pair exists in
		-- important for _createActivePairsList to work
		local bodyB = bucket[i]
		local pairId = Pair.id(body, bodyB)
		local pair = grid.pairs[pairId]

		if (pair) then
			pair[3] -= 1
		end
	end
end

--[[
 * Generates a list of the active pairs in the grid.
 * @method _createActivePairsList
 * @private
 * @param {} grid
 * @return [] pairs
 ]]--

function Grid._createActivePairsList(grid)

	-- print('Grid._createActivePairsList ', table.size(grid.pairs))

	local pairs = {}
	local pairKeys,
		pair

	-- grid.pairs is used as a hashmap
	pairKeys = Common.keys(grid.pairs)

	local n = #pairKeys

	-- iterate over grid.pairs
	for k = 1, n do
		pair = grid.pairs[pairKeys[k]]

		-- if pair exists in at least one bucket
		-- it is a pair that needs further collision testing so push it

		if (pair[3] > 0) then
			table.insert(pairs, pair)
		else
			grid.pairs[pairKeys[k]] = nil
		end
	end

	-- printTable(pairs)

	return pairs
end

