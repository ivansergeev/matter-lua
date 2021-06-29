--[[
* The `Matter.Detector` module contains methods for detecting collisions given a set of pairs.
*
* @class Detector
]]--

-- TODO: speculative contacts

import 'matter/collision/SAT'
import 'matter/collision/Pair'
import 'matter/geometry/Bounds'

local DetectorCanCollide

Detector = {}
Detector.__index = Detector

--[[
 * Finds all collisions given a list of pairs.
 * @method collisions
 * @param {pair[]} broadphasePairs
 * @param {engine} engine
 * @return {array} collisions
 ]]--

function Detector.collisions(broadphasePairs, engine)

	-- print('Detector.collisions ', #broadphasePairs)

	local collisions = {}
	local pairsTable = engine.pairs.table
	local n = #broadphasePairs
	local SATCollides = SAT.collides
	local BoundsOverlaps = Bounds.overlaps

	-- @if DEBUG
	-- local metrics = engine.metrics
	-- @endif

	local bodyA, bodyB,
		b1, b2,
		partA, partB,
		partAId, partBId,
		pairId, pair,
		previousCollision,
		collision,
		bodyABounds, bodyBBounds

	for i = 1, n do
		repeat

			bodyA = broadphasePairs[i][1]
			bodyB = broadphasePairs[i][2]

			if ((bodyA.isStatic or bodyA.isSleeping) and (bodyB.isStatic or bodyB.isSleeping)) then
				break
			end

			if (not DetectorCanCollide(bodyA.collisionFilter, bodyB.collisionFilter)) then
				break
			end

			-- @if DEBUG
			-- metrics.midphaseTests += 1
			-- @endif

			-- mid phase

			if (BoundsOverlaps(bodyA.bounds, bodyB.bounds)) then

				b1 = #bodyA.parts

				for j = b1 > 1 and 2 or 1, b1 do

					partA = bodyA.parts[j]
					b2 = #bodyB.parts

					for k = b2 > 1 and 2 or 1, b2 do

						partB = bodyB.parts[k]

						if ((partA == bodyA and partB == bodyB) or BoundsOverlaps(partA.bounds, partB.bounds)) then

							-- find a previous collision we could reuse
							partAId, partBId = partA.id, partA.id

							pairId = Pair.id(partA, partB)
							pair = pairsTable[pairId]
							previousCollision = (pair and pair.isActive) and pair.collision or nil


							-- narrow phase

						-- sample('SAT sample', function()
							collision = SATCollides(partA, partB, previousCollision)

							-- collision = SATCollides(partA, partB, (pair and pair.isActive) and pair.collision or nil)

						-- end)

							-- @if DEBUG
							--[[
							metrics.narrowphaseTests += 1
							if (collision.reused) then
								metrics.narrowReuseCount += 1
							end
							]]--
							-- @endif

							if (collision.collided) then
								table.insert(collisions, collision)

								-- @if DEBUG
								-- metrics.narrowDetections += 1;
								-- @endif
							end
						end
					end
				end
			end
		break
		until true
	end

	return collisions
end

--[[
 * Returns `true` if both supplied collision filters will allow a collision to occur.
 * See `body.collisionFilter` for more information.
 * @method canCollide
 * @param {} filterA
 * @param {} filterB
 * @return {bool} `true` if collision can occur
 ]]--

function Detector.canCollide(filterA, filterB)
	if (filterA.group == filterB.group and filterA.group ~= 0) then
		return filterA.group > 0
	end

	return (filterA.mask & filterB.category) ~= 0 and (filterB.mask & filterA.category) ~= 0
end

DetectorCanCollide = Detector.canCollide
