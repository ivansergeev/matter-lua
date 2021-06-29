--[[
* The `Matter.Pairs` module contains methods for creating and manipulating collision pair sets.
*
* @class Pairs
]]--

import 'matter/collision/Pair'
import 'matter/core/Common'

Pairs = {}
Pairs.__index = Pairs


Pairs._pairMaxIdleLife = 1000

--[[
 * Creates a new pairs structure.
 * @method create
 * @param {object} options
 * @return {pairs} A new pairs structure
 ]]--
function Pairs.create(options)
	return Common.extend({
		table = {},
		list = {},
		collisionStart = {},
		collisionActive = {},
		collisionEnd = {}
	}, options)
end

--[[
 * Updates pairs given a list of collisions.
 * @method update
 * @param {object} pairs
 * @param {collision[]} collisions
 * @param {number} timestamp
 ]]--

function Pairs.update(pairs, collisions, timestamp)

	-- print('Pairs.update', #collisions, timestamp)

	local pairsList = pairs.list
	local pairsTable = pairs.table
	local collisionStart = pairs.collisionStart
	local collisionEnd = pairs.collisionEnd
	local collisionActive = pairs.collisionActive
	local collision,
		pairId,
		pair

	-- clear collision state arrays, but maintain old reference
	collisionStart = {}
	collisionEnd = {}
	collisionActive = {}

	local n = #pairsList

	for i = 1, n do
		pairsList[i].confirmedActive = false
	end

	local c = #collisions
	for i = 1, c do
		collision = collisions[i]

		if (collision.collided) then
			pairId = Pair.id(collision.bodyA, collision.bodyB)
			pair = pairsTable[pairId]

			if (pair) then
				-- pair already exists (but may or may not be active)
				if (pair.isActive) then
					-- pair exists and is active
					table.insert(collisionActive, pair)
				else
					-- pair exists but was inactive, so a collision has just started again
					table.insert(collisionStart, pair)
				end

				-- update the pair

				Pair.update(pair, collision, timestamp)
				pair.confirmedActive = true
			else
				-- pair did not exist, create a new pair
				pair = Pair.create(collision, timestamp)
				pairsTable[pairId] = pair

				-- push the new pair

				table.insert(collisionStart, pair)
				table.insert(pairsList, pair)
			end
		end
	end

	-- if #pairs.list > 0 then
	-- end

	-- deactivate previously active pairs that are now inactive
	local p = #pairsList

	for i = 1, p do
		pair = pairsList[i]
		if (pair.isActive and not pair.confirmedActive) then
			Pair.setActive(pair, false, timestamp)
			table.insert(collisionEnd, pair)
		end
	end
end

--[[
 * Finds and removes pairs that have been inactive for a set amount of time.
 * @method removeOld
 * @param {object} pairs
 * @param {number} timestamp
 ]]--

function Pairs.removeOld(pairs, timestamp)

	local pairsList = pairs.list
	local pairsTable = pairs.table
	local indexesToRemove = {}
	local pair,
		collision,
		pairIndex

	local n = #pairsList

	for i = 1, n do
		repeat
			pair = pairsList[i]
			collision = pair.collision

			-- never remove sleeping pairs
			if (collision.bodyA.isSleeping or collision.bodyB.isSleeping) then
				pair.timeUpdated = timestamp
				break
			end

			-- if pair is inactive for too long, mark it to be removed
			if (timestamp - pair.timeUpdated > Pairs._pairMaxIdleLife) then
				table.insert(indexesToRemove, i)
			end
		break
		until true
	end

	-- remove marked pairs
	local r = #indexesToRemove

	for i = 1, r do
		pairIndex = indexesToRemove[i] - i
		if pairIndex > 0 then
			pair = pairsList[pairIndex]

			-- if pair then
				pairsTable[pair.id] = nil
				table.remove(pairsList, pairIndex)
			-- end
		end
	end
end

--[[
 * Clears the given pairs structure.
 * @method clear
 * @param {pairs} pairs
 * @return {pairs} pairs
 ]]--

function Pairs.clear(pairs)
	pairs.table = {}
	pairs.list = {}
	pairs.collisionStart = {}
	pairs.collisionActive = {}
	pairs.collisionEnd = {}
	return pairs
end