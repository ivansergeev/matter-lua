--[[
* The `Matter.Sleeping` module contains methods to manage the sleeping state of bodies.
*
* @class Sleeping
]]--

import 'matter/core/Events'

Sleeping = {}
Sleeping.__index = Sleeping

Sleeping._motionWakeThreshold = 0.18
Sleeping._motionSleepThreshold = 0.08
Sleeping._minBias = 0.9

--[[
 * Puts bodies to sleep or wakes them up depending on their motion.
 * @method update
 * @param {body[]} bodies
 * @param {number} timeScale
 ]]--

function Sleeping.update(bodies, timeScale)

	local timeFactor = timeScale * timeScale * timeScale
	local n = #bodies

	-- update bodies sleeping status
	for i = 1, n do
		repeat

			local body = bodies[i]
			local motion = body.speed * body.speed + body.angularSpeed * body.angularSpeed

			-- wake up bodies if they have a force applied
			if (body.force.x ~= 0 or body.force.y ~= 0) then
				Sleeping.set(body, false)
				break
			end

			local minMotion = math.min(body.motion, motion)
			local maxMotion = math.max(body.motion, motion)

			-- biased average motion estimation between frames
			body.motion = Sleeping._minBias * minMotion + (1 - Sleeping._minBias) * maxMotion

			if (body.sleepThreshold > 0 and body.motion < Sleeping._motionSleepThreshold * timeFactor) then

				body.sleepCounter += 1

				if (body.sleepCounter >= body.sleepThreshold) then
					Sleeping.set(body, true)
				end

			elseif (body.sleepCounter > 0) then
				body.sleepCounter -= 1
			end
		break
		until true
	end
end

--[[
 * Given a set of colliding pairs, wakes the sleeping bodies involved.
 * @method afterCollisions
 * @param {pair[]} pairs
 * @param {number} timeScale
 ]]--

Sleeping.afterCollisions = function(pairs, timeScale)
	local timeFactor = timeScale * timeScale * timeScale
	local n = #pairs

	-- wake up bodies involved in collisions
	for i = 1, n do
		repeat

			local pair = pairs[i]

			-- don't wake inactive pairs
			if (not pair.isActive) then
				break
			end

			local collision = pair.collision
			local bodyA = collision.bodyA.parent
			local bodyB = collision.bodyB.parent

			-- don't wake if at least one body is static
			if ((bodyA.isSleeping and bodyB.isSleeping) or bodyA.isStatic or bodyB.isStatic) then
				break
			end

			if (bodyA.isSleeping or bodyB.isSleeping) then
				local sleepingBody = (bodyA.isSleeping and not bodyA.isStatic) and bodyA or bodyB
				local movingBody = sleepingBody == bodyA and bodyB or bodyA

				if (not sleepingBody.isStatic and movingBody.motion > Sleeping._motionWakeThreshold * timeFactor) then
					Sleeping.set(sleepingBody, false)
				end
			end

		break
		until true
	end
end

--[[
 * Set a body as sleeping or awake.
 * @method set
 * @param {body} body
 * @param {boolean} isSleeping
 ]]--
function Sleeping.set(body, isSleeping)

	local wasSleeping = body.isSleeping

	if (isSleeping) then
		body.isSleeping = true
		body.sleepCounter = body.sleepThreshold

		body.positionImpulse.x = 0
		body.positionImpulse.y = 0

		body.positionPrev.x = body.position.x
		body.positionPrev.y = body.position.y

		body.anglePrev = body.angle
		body.speed = 0
		body.angularSpeed = 0
		body.motion = 0

		if (not wasSleeping) then
			Events.trigger(body, 'sleepStart')
		end

	else
		body.isSleeping = false
		body.sleepCounter = 0

		if (wasSleeping) then
			Events.trigger(body, 'sleepEnd')
		end
	end
end
