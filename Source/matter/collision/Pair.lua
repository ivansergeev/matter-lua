--[[
* The `Matter.Pair` module contains methods for creating and manipulating collision pairs.
*
* @class Pair
]]--

import 'matter/collision/Contact'

Pair = {}
Pair.__index = Pair

--[[
 * Creates a pair.
 * @method create
 * @param {collision} collision
 * @param {number} timestamp
 * @return {pair} A new pair
 ]]--

function Pair.create(collision, timestamp)

	-- print('Pair.create')

	local bodyA = collision.bodyA
	local bodyB = collision.bodyB
	local parentA = collision.parentA
	local parentB = collision.parentB

	local pair = {
		id = Pair.id(bodyA, bodyB),
		bodyA = bodyA,
		bodyB = bodyB,
		contacts = {},
		activeContacts = {},
		separation = 0,
		isActive = true,
		confirmedActive = true,
		isSensor = bodyA.isSensor or bodyB.isSensor,
		timeCreated = timestamp,
		timeUpdated = timestamp,
		inverseMass = parentA.inverseMass + parentB.inverseMass,
		friction = math.min(parentA.friction, parentB.friction),
		frictionStatic = math.max(parentA.frictionStatic, parentB.frictionStatic),
		restitution = math.max(parentA.restitution, parentB.restitution),
		slop = math.max(parentA.slop, parentB.slop),
	}

	Pair.update(pair, collision, timestamp)

	return pair
end

--[[
 * Updates a pair given a collision.
 * @method update
 * @param {pair} pair
 * @param {collision} collision
 * @param {number} timestamp
 ]]--

function Pair.update(pair, collision, timestamp)

	-- print('Pair.update')

	local contacts = pair.contacts
	local supports = collision.supports
	pair.activeContacts = {}
	local activeContacts = pair.activeContacts
	local parentA = collision.parentA
	local parentB = collision.parentB

	pair.collision = collision
	pair.inverseMass = parentA.inverseMass + parentB.inverseMass
	pair.friction = math.min(parentA.friction, parentB.friction)
	pair.frictionStatic = math.max(parentA.frictionStatic, parentB.frictionStatic)
	pair.restitution = math.max(parentA.restitution, parentB.restitution)
	pair.slop = math.max(parentA.slop, parentB.slop)

	-- set activeContacts length in upper (pair.activeContacts = {})

	if (collision.collided) then

		local n = #supports

		for i = 1, n do
			local support = supports[i]
			local contactId = Contact.id(support)
			local contact = contacts[contactId]

			if (contact) then
				table.insert(activeContacts, contact)
			else
				contacts[contactId] = Contact.create(support)
				table.insert(activeContacts, contacts[contactId])
			end
		end

		pair.separation = collision.depth
		Pair.setActive(pair, true, timestamp)
	else
		if (pair.isActive == true) then
			Pair.setActive(pair, false, timestamp)
		end
	end
end

--[[
 * Set a pair as active or inactive.
 * @method setActive
 * @param {pair} pair
 * @param {bool} isActive
 * @param {number} timestamp
 ]]--

function Pair.setActive(pair, isActive, timestamp)
	if (isActive) then
		pair.isActive = true
		pair.timeUpdated = timestamp
	else
		pair.isActive = false
		pair.activeContacts = {}
	end
end

--[[
 * Get the id for the given pair.
 * @method id
 * @param {body} bodyA
 * @param {body} bodyB
 * @return {string} Unique pairId
 ]]--

function Pair.id(bodyA, bodyB)
	if (bodyA.id < bodyB.id) then
		return 'A' .. bodyA.id .. 'B' .. bodyB.id
	else
		return 'A' .. bodyB.id .. 'B' .. bodyA.id
	end
end
