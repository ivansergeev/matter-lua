--[[
* The `Matter.Render` module is a simple HTML5 canvas based renderer for visualising instances of `Matter.Engine`.
* It is intended for development and debugging purposes, but may also be suitable for simple games.
* It includes a number of drawing options including wireframe, vector with support for sprites and viewports.
*
* @class Render
]]--

import 'matter/core/Common'
import 'matter/body/Composite'
import 'matter/geometry/Bounds'
import 'matter/core/Events'
import 'matter/collision/Grid'
import 'matter/geometry/Vector'

local gfx <const> = playdate.graphics
local geom <const> = playdate.geometry

Render = {}
Render.__index = Render

--[[
 * Description
 * @method _createCanvas
 * @private
 * @param {} width
 * @param {} height
 * @return canvas
 ]]--

local function _createCanvas(width, height)
	return {
		width = width,
		height = height
	}
end

--[[
 * Gets the pixel ratio of the canvas.
 * @method _getPixelRatio
 * @private
 * @param {HTMLElement} canvas
 * @return {Number} pixel ratio
 ]]--

local function _getPixelRatio(canvas)

	local context = canvas.getContext('2d')
	local devicePixelRatio = window.devicePixelRatio or 1
	local backingStorePixelRatio = context.webkitBackingStorePixelRatio or context.mozBackingStorePixelRatio
								or context.msBackingStorePixelRatio or context.oBackingStorePixelRatio
								or context.backingStorePixelRatio or 1

	return devicePixelRatio / backingStorePixelRatio
end

--[[
 * Gets the requested texture (an Image) via its path
 * @method _getTexture
 * @private
 * @param {render} render
 * @param {string} imagePath
 * @return {Image} texture
 ]]--

local function _getTexture(render, imagePath)
	return nil
end

--[[
 * Applies the background to the canvas using CSS.
 * @method applyBackground
 * @private
 * @param {render} render
 * @param {string} background
 ]]--
local function _applyBackground(render, background)
	return nil
end

--[[
 * Creates a new renderer. The options parameter is an object that specifies any properties you wish to override the defaults.
 * All properties have default values, and many are pre-calculated automatically based on other properties.
 * See the properties section below for detailed information on what you can pass via the `options` object.
 * @method create
 * @param {object} [options]
 * @return {render} A new renderer
 ]]--

function Render.create(options)

	local defaults = {
		controller = Render,
		engine = nil,
		element = nil,
		canvas = nil,
		mouse = false,
		frameRequestId = nil,
		options = {
			width = 400,
			height = 240,
			pixelRatio = 1,
			background = nil, -- color
			wireframeBackground = nil, -- color
			hasBounds = not not options.bounds,
			enabled = true,
			wireframes = true,
			showSleeping = true,
			showDebug = false,
			showBroadphase = false,
			showBounds = false,
			showVelocity = false,
			showCollisions = false,
			showSeparations = false,
			showAxes = false,
			showPositions = false,
			showAngleIndicator = false,
			showIds = false,
			showShadows = false,
			showVertexNumbers = false,
			showConvexHulls = false,
			showInternalEdges = false,
			showMousePosition = false,
		}
	}

	local render = Common.extend(defaults, options)
	render.engine = options.engine
	render.canvas = render.canvas or _createCanvas(render.options.width, render.options.height)
	render.context = nil
	render.textures = {}

	render.bounds = render.bounds or {
		min = {
			x = 0,
			y = 0
		},
		max = {
			x = render.canvas.width,
			y = render.canvas.height
		}
	}

	if (render.options.pixelRatio ~= 1) then
		Render.setPixelRatio(render, render.options.pixelRatio)
	end

	return render
end

--[[
 * Continuously updates the render canvas on the `requestAnimationFrame` event.
 * @method run
 * @param {render} render
 ]]--
function Render.run(render)
	Render.world(render)
end

--[[
 * Ends execution of `Render.run` on the given `render`, by canceling the animation frame request event loop.
 * @method stop
 * @param {render} render
 ]]--
function Render.stop(render)
	-- _cancelAnimationFrame(render.frameRequestId)
end

--[[
 * Sets the pixel ratio of the renderer and updates the canvas.
 * To automatically detect the correct ratio, pass the string `'auto'` for `pixelRatio`.
 * @method setPixelRatio
 * @param {render} render
 * @param {number} pixelRatio
 ]]--

function Render.setPixelRatio(render, pixelRatio)

	local options = render.options
	local canvas = render.canvas

	if (pixelRatio == 'auto') then
		pixelRatio = _getPixelRatio(canvas)
	end

	options.pixelRatio = pixelRatio
	canvas.setAttribute('data-pixel-ratio', pixelRatio)
	canvas.width = options.width * pixelRatio
	canvas.height = options.height * pixelRatio
	canvas.style.width = options.width + 'px'
	canvas.style.height = options.height + 'px'
end

--[[
 * Positions and sizes the viewport around the given object bounds.
 * Objects must have at least one of the following properties:
 * - `object.bounds`
 * - `object.position`
 * - `object.min` and `object.max`
 * - `object.x` and `object.y`
 * @method lookAt
 * @param {render} render
 * @param {object[]} objects
 * @param {vector} [padding]
 * @param {bool} [center=true]
 ]]--
function Render.lookAt(render, objects, padding, center)

	center = type(center) ~= 'nil' and center or true
	objects = Common.isArray(objects) and objects or {objects}
	padding = padding or {
		x = 0,
		y = 0,
	}

	-- find bounds of all objects
	local bounds = {
		min = { x = Infinity, y = Infinity },
		max = { x = -Infinity, y = -Infinity },
	}

	local n = #objects
	for i = 1, n do
		local object = objects[i]
		local min = object.bounds and object.bounds.min or (object.min or object.position or object)
		local max = object.bounds and object.bounds.max or (object.max or object.position or object)

		if (min and max) then
			if (min.x < bounds.min.x) then
				bounds.min.x = min.x
			end

			if (max.x > bounds.max.x) then
				bounds.max.x = max.x
			end

			if (min.y < bounds.min.y) then
				bounds.min.y = min.y
			end

			if (max.y > bounds.max.y) then
				bounds.max.y = max.y
			end
		end
	end

	-- find ratios
	local width = (bounds.max.x - bounds.min.x) + 2 * padding.x
	local	height = (bounds.max.y - bounds.min.y) + 2 * padding.y
	local	viewHeight = render.canvas.height
	local	viewWidth = render.canvas.width
	local	outerRatio = viewWidth / viewHeight
	local	innerRatio = width / height
	local	scaleX = 1
	local	scaleY = 1

	-- find scale factor
	if (innerRatio > outerRatio) then
		scaleY = innerRatio / outerRatio
	else
		scaleX = outerRatio / innerRatio
	end

	-- enable bounds
	render.options.hasBounds = true

	-- position and size
	render.bounds.min.x = bounds.min.x
	render.bounds.max.x = bounds.min.x + width * scaleX
	render.bounds.min.y = bounds.min.y
	render.bounds.max.y = bounds.min.y + height * scaleY

	-- center
	if (center) then
		render.bounds.min.x += width * 0.5 - (width * scaleX) * 0.5
		render.bounds.max.x += width * 0.5 - (width * scaleX) * 0.5
		render.bounds.min.y += height * 0.5 - (height * scaleY) * 0.5
		render.bounds.max.y += height * 0.5 - (height * scaleY) * 0.5
	end

	-- padding
	render.bounds.min.x -= padding.x
	render.bounds.max.x -= padding.x
	render.bounds.min.y -= padding.y
	render.bounds.max.y -= padding.y

end

--[[
 * Applies viewport transforms based on `render.bounds` to a render context.
 * @method startViewTransform
 * @param {render} render
 ]]--

function Render.startViewTransform(render)

	local boundsWidth = render.bounds.max.x - render.bounds.min.x
	local boundsHeight = render.bounds.max.y - render.bounds.min.y
	local boundsScaleX = boundsWidth / render.options.width
	local boundsScaleY = boundsHeight / render.options.height

	render.context.setTransform(
		render.options.pixelRatio / boundsScaleX, 0, 0,
		render.options.pixelRatio / boundsScaleY, 0, 0
	)

	render.context.translate(-render.bounds.min.x, -render.bounds.min.y)
end

--[[
 * Resets all transforms on the render context.
 * @method endViewTransform
 * @param {render} render
 ]]--

function Render.endViewTransform(render)
	render.context.setTransform(render.options.pixelRatio, 0, 0, render.options.pixelRatio, 0, 0)
end

--[[
 * Renders the given `engine`'s `Matter.World` object.
 * This is the entry point for all rendering and should be called every time the scene changes.
 * @method world
 * @param {render} render
 ]]--

function Render.world(render)

	local engine = render.engine
	local world = engine.world
	local canvas = render.canvas
	local context = render.context
	local options = render.options
	local allBodies = Composite.allBodies(world)
	local allConstraints = Composite.allConstraints(world)
	local background = options.wireframes and options.wireframeBackground or options.background
	local bodies = {}
	local constraints = {}

	local event = {
		timestamp = engine.timing.timestamp
	}

	Events.trigger(render, 'beforeRender', event)

	-- apply background if it has changed
	if (render.currentBackground ~= background) then
		_applyBackground(render, background)
	end

	-- clear the canvas with a transparent fill, to allow the canvas background to show

	-- handle bounds
	if (options.hasBounds) then
		-- filter out bodies that are not in view
		local n = #allBodies
		for i = 1, n do
			local body = allBodies[i]
			if (Bounds.overlaps(body.bounds, render.bounds)) then
				table.insert(bodies, body)
			end
		end

		-- filter out constraints that are not in view
		local n = #allConstraints
		for i = 1, n do
			repeat

				local constraint = allConstraints[i]
				local bodyA = constraint.bodyA
				local bodyB = constraint.bodyB
				local pointAWorld = constraint.pointA
				local pointBWorld = constraint.pointB

				if (bodyA) then
					pointAWorld = Vector.add(bodyA.position, constraint.pointA)
				end

				if (bodyB) then
					pointBWorld = Vector.add(bodyB.position, constraint.pointB)
				end

				if (not pointAWorld or not pointBWorld) then
					break
				end

				if (Bounds.contains(render.bounds, pointAWorld) or Bounds.contains(render.bounds, pointBWorld)) then
					table.insert(constraints, constraint)
				end
			break
			until true
		end

		-- transform the view
		Render.startViewTransform(render)

	else
		constraints = allConstraints
		bodies = allBodies

		if (render.options.pixelRatio ~= 1) then
			render.context.setTransform(render.options.pixelRatio, 0, 0, render.options.pixelRatio, 0, 0)
		end
	end

	if (not options.wireframes or (engine.enableSleeping and options.showSleeping)) then
		-- fully featured rendering of bodies
		Render.bodies(render, bodies, context)
	else
		if (options.showConvexHulls) then
			Render.bodyConvexHulls(render, bodies, context)
		end
		-- optimised method for wireframes only
		Render.bodyWireframes(render, bodies, context)
	end

	if (options.showBounds)	then
		Render.bodyBounds(render, bodies, context)
	end

	if (options.showAxes or options.showAngleIndicator)	then
		Render.bodyAxes(render, bodies, context)
	end

	if (options.showPositions) then
		Render.bodyPositions(render, bodies, context)
	end

	if (options.showVelocity) then
		Render.bodyVelocity(render, bodies, context)
	end

	if (options.showIds) then
		Render.bodyIds(render, bodies, context)
	end

	if (options.showSeparations) then
		Render.separations(render, engine.pairs.list, context)
	end

	if (options.showCollisions)	then
		Render.collisions(render, engine.pairs.list, context)
	end

	if (options.showVertexNumbers) then
		Render.vertexNumbers(render, bodies, context)
	end

	Render.constraints(constraints, context)

	if (options.showBroadphase and engine.broadphase.controller == Grid) then
		Render.grid(render, engine.broadphase, context)
	end

	if (options.showDebug) then
		Render.debug(render, context)
	end

	if (options.hasBounds) then
		-- revert view transforms
		Render.endViewTransform(render)
	end

	Events.trigger(render, 'afterRender', event)
end

--[[
 * Description
 * @private
 * @method debug
 * @param {render} render
 * @param {RenderingContext} context
 ]]--

function Render.debug(render, context)
	local c = context
	local engine = render.engine
	local world = engine.world
	local metrics = engine.metrics
	local options = render.options
	local bodies = Composite.allBodies(world)
	local space = ' '

	if (engine.timing.timestamp - (render.debugTimestamp or 0) >= 500) then
		local text = ''

		if (metrics.timing) then
			text += 'fps: ' + math.round(metrics.timing.fps) + space
		end

		-- @if DEBUG
		--[[
		if (metrics.extended) then
			if (metrics.timing) then
				text += "delta: " + metrics.timing.delta.toFixed(3) + space
				text += "correction: " + metrics.timing.correction.toFixed(3) + space
			}

			text += "bodies: " + bodies.length + space

			if (engine.broadphase.controller == Grid)
				text += "buckets: " + metrics.buckets + space
			end

			text += "\n"

			text += "collisions: " + metrics.collisions + space
			text += "pairs: " + engine.pairs.list.length + space
			text += "broad: " + metrics.broadEff + space
			text += "mid: " + metrics.midEff + space
			text += "narrow: " + metrics.narrowEff + space
		end
		]]--
		-- @endif

		render.debugString = text
		render.debugTimestamp = engine.timing.timestamp
	end


	--[[
		if (render.debugString) then
			local split = render.debugString.split('\n')

			for (local i = 0 i < split.length i++) do
				c.fillText(split[i], 50, 50 + i * 18)
			end
		end
	]]--

end

--[[
 * Description
 * @private
 * @method constraints
 * @param {constraint[]} constraints
 * @param {RenderingContext} context
 ]]--

function Render.constraints(constraints, context)

	local c = context
	local n = #constraints

	for i = 1, n do
		repeat

			local constraint = constraints[i]

			if (not constraint.render.visible or not constraint.pointA or not constraint.pointB) then
				break
			end

			local bodyA = constraint.bodyA
			local bodyB = constraint.bodyB
			local _start,
				_end

			if (bodyA) then
				_start = Vector.add(bodyA.position, constraint.pointA)
			else
				_start = constraint.pointA
			end

			if (constraint.render.type == 'pin') then
				c.beginPath()
				c.arc(_start.x, _start.y, 3, 0, 2 * math.pi)
				c.closePath()
			else
				if (bodyB) then
					_end = Vector.add(bodyB.position, constraint.pointB)
				else
					_end = constraint.pointB
				end

				c.beginPath()
				c.moveTo(_start.x, _start.y)

				if (constraint.render.type == 'spring') then
					local delta = Vector.sub(_end, _start)
					local normal = Vector.perp(Vector.normalise(delta))
					local coils = math.ceil(Common.clamp(constraint.length / 5, 12, 20))
					local offset

					for j = 1, coils do
						offset = j % 2 == 0 and 1 or -1

						c.lineTo(
							_start.x + delta.x * (j / coils) + normal.x * offset * 4,
							_start.y + delta.y * (j / coils) + normal.y * offset * 4
						)
					end
				end

				c.lineTo(_end.x, _end.y)
			end

			if (constraint.render.lineWidth) then
				c.lineWidth = constraint.render.lineWidth
				c.strokeStyle = constraint.render.strokeStyle
				c.stroke()
			end

			if (constraint.render.anchors) then
				c.fillStyle = constraint.render.strokeStyle
				c.beginPath()
				c.arc(_start.x, _start.y, 3, 0, 2 * math.pi)
				c.arc(_end.x, _end.y, 3, 0, 2 * math.pi)
				c.closePath()
				c.fill()
			end
		break
		until true
	end
end

--[[
 * Description
 * @private
 * @method bodyShadows
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--

Render.bodyShadows = function(render, bodies, context)

	local c = context
	local engine = render.engine
	local n = #bodies

	for i = 1, n do

		repeat
			local body = bodies[i]

			if (not body.render.visible) then
				break
			end

			if (body.circleRadius) then
				c.beginPath()
				c.arc(body.position.x, body.position.y, body.circleRadius, 0, 2 * math.pi)
				c.closePath()
			else
				c.beginPath()
				c.moveTo(body.vertices[0].x, body.vertices[0].y)

				local v = #body.vertices
				for j = 2, v do
					c.lineTo(body.vertices[j].x, body.vertices[j].y)
				end
				c.closePath()
			end

			local distanceX = body.position.x - render.options.width * 0.5
			local distanceY = body.position.y - render.options.height * 0.2
			local distance = math.abs(distanceX) + math.abs(distanceY)

			c.shadowColor = 'rgba(0,0,0,0.15)'
			c.shadowOffsetX = 0.05 * distanceX
			c.shadowOffsetY = 0.05 * distanceY
			c.shadowBlur = 1 + 12 * Math.min(1, distance / 1000)

			c.fill()

			c.shadowColor = nil
			c.shadowOffsetX = nil
			c.shadowOffsetY = nil
			c.shadowBlur = nil

		break
		until true
	end
end

--[[
 * Description
 * @private
 * @method bodies
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--

function Render.bodies(render, bodies, context)

	-- print('Render.bodies')

	local c = context
	local engine = render.engine
	local options = render.options
	local showInternalEdges = options.showInternalEdges or not options.wireframes
	local body,
		part

	local n = #bodies
	for i = 1, n do
		repeat

			body = bodies[i]

			if (not body.render.visible) then
				break
			end

			-- handle compound parts
			local p = #body.parts
			for k = p > 1 and 2 or 1, p do
				repeat

					part = body.parts[k]

					if (not part.render.visible) then
						break
					end

					if (options.showSleeping and body.isSleeping) then
						c.globalAlpha = 0.5 * part.render.opacity
					elseif (part.render.opacity ~= 1) then
						c.globalAlpha = part.render.opacity
					end

					if (part.render.sprite and part.render.sprite.texture and not options.wireframes) then
						-- part sprite
						local sprite = part.render.sprite
						local texture = _getTexture(render, sprite.texture)

						c.translate(part.position.x, part.position.y)
						c.rotate(part.angle)

						c.drawImage(
							texture,
							texture.width * -sprite.xOffset * sprite.xScale,
							texture.height * -sprite.yOffset * sprite.yScale,
							texture.width * sprite.xScale,
							texture.height * sprite.yScale
						)

						-- revert translation, hopefully faster than save / restore
						c.rotate(-part.angle)
						c.translate(-part.position.x, -part.position.y)

					else
						-- part polygon
						if (part.circleRadius) then
							c.beginPath()
							c.arc(part.position.x, part.position.y, part.circleRadius, 0, 2 * math.pi)
						else
							c.beginPath()
							c.moveTo(part.vertices[0].x, part.vertices[0].y)

							local v = #part.vertices

							for j = 2, v do
								if (not part.vertices[j - 1].isInternal or showInternalEdges) then
									c.lineTo(part.vertices[j].x, part.vertices[j].y)
								else
									c.moveTo(part.vertices[j].x, part.vertices[j].y)
								end

								if (part.vertices[j].isInternal and not showInternalEdges) then
									c.moveTo(part.vertices[(j + 1) % part.vertices.length].x, part.vertices[(j + 1) % part.vertices.length].y)
								end
							end

							c.lineTo(part.vertices[0].x, part.vertices[0].y)
							c.closePath()
						end

						if (not options.wireframes) then
							c.fillStyle = part.render.fillStyle

							if (part.render.lineWidth) then
								c.lineWidth = part.render.lineWidth
								c.strokeStyle = part.render.strokeStyle
								c.stroke()
							end

							c.fill()

						else
							c.lineWidth = 1
							c.strokeStyle = '#bbb'
							c.stroke()
						end
					end

					c.globalAlpha = 1
				break
				until true
			end
		break
		until true
	end
end

--[[
 * Optimised method for drawing body wireframes in one pass
 * @private
 * @method bodyWireframes
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--

function Render.bodyWireframes(render, bodies, context)

	-- print('Render.bodyWireframes')

	local showInternalEdges = render.options.showInternalEdges
	local n = #bodies
	local body,
		part

	gfx.setLineWidth(1)
	gfx.setColor(gfx.kColorBlack)

	for i = 1, n do
		repeat

			body = bodies[i]

			if (not body.render.visible or body.position.x > 400 or body.position.x < 0 or body.position.y < 0 or body.position.y > 240) then
				break
			end

			-- draw circle
			if (body.circleRadius > 0) then
				gfx.drawCircleAtPoint(body.position.x, body.position.y, body.circleRadius)
				break
			end

			-- handle compound parts
			local p = #body.parts

			for k = p > 1 and 2 or 1, p do

				part = body.parts[k]

				local vertices = Table{}

				vertices:push(part.vertices[1].x)
						:push(part.vertices[1].y)

				local v = #part.vertices
				for j = 1, v do

					vertices:push(part.vertices[j].x)
							:push(part.vertices[j].y)

					if (part.vertices[j].isInternal and not showInternalEdges) then

						local index = (j + 1) % #part.vertices
						index = index ~=0 and index or #part.vertices

						vertices:push(part.vertices[index].x)
								:push(part.vertices[index].y)
						-- vertices:push(part.vertices[(j + 1) % #part.vertices].x)
						-- 		:push(part.vertices[(j + 1) % #part.vertices].y)

					end

					if (part.vertices[j].isInternal) then
						gfx.fillCircleAtPoint(part.vertices[j].x, part.vertices[j].y, 3)
					end

				end

				gfx.drawPolygon(table.unpack(vertices))
			end

			break
		until true
	end

end

function Render.bodyWireframes__(render, bodies, context)

	local c = context
	local showInternalEdges = render.options.showInternalEdges
	local n = #bodies
	local body,
		part


	if (n > 0) then
		c.beginPath()
	end

	-- render all bodies

	for i = 1, n do
		repeat

			body = bodies[i]

			if (not body.render.visible) then
				break
			end

			-- handle compound parts
			local p = #body.parts
			for k = p > 1 and 2 or 1, p do

				part = body.parts[k]

				c.moveTo(part.vertices[1].x, part.vertices[1].y)

				local v = #part.vertices

				for j = 1, v do
					if (not part.vertices[j - 1].isInternal or showInternalEdges) then
						c.lineTo(part.vertices[j].x, part.vertices[j].y)
					else
						c.moveTo(part.vertices[j].x, part.vertices[j].y)
					end

					if (part.vertices[j].isInternal and not showInternalEdges) then
						c.moveTo(part.vertices[(j + 1) % part.vertices.length].x, part.vertices[(j + 1) % part.vertices.length].y)
					end
				end

				c.lineTo(part.vertices[0].x, part.vertices[0].y)
			end
		break
		until true
	end

	if (n > 0) then
		c.lineWidth = 1
		c.strokeStyle = '#bbb'
		c.stroke()
	end
end

--[[
 * Optimised method for drawing body convex hull wireframes in one pass
 * @private
 * @method bodyConvexHulls
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--

function Render.bodyConvexHulls(render, bodies, context)

	local c = context,
		body,
		part

	c.beginPath()

	-- render convex hulls
	local n = #bodies
	for i = 1, n do
		repeat
			body = bodies[i]

			if (not body.render.visible or body.parts.length == 1) then
				break
			end
			c.moveTo(body.vertices[0].x, body.vertices[0].y)

			local v = #body.vertices
			for j = 2, v do
				c.lineTo(body.vertices[j].x, body.vertices[j].y)
			end

			c.lineTo(body.vertices[0].x, body.vertices[0].y)
		break
		until true
	end

	c.lineWidth = 1
	c.strokeStyle = 'rgba(255,255,255,0.2)'
	c.stroke()
end

--[[
 * Renders body vertex numbers.
 * @private
 * @method vertexNumbers
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--

function Render.vertexNumbers(render, bodies, context)

	local n = #bodies

	for i = 1, n do

		local parts = bodies[i].parts
		local p = #parts

		for k = p > 1 and 2 or 1, p do

			local part = parts[k]
			local v = #part.vertices

			for j = 1, v do
				gfx.drawText(i .. '-' .. j, part.position.x + (part.vertices[j].x - part.position.x) * 0.95, part.position.y + (part.vertices[j].y - part.position.y) * 0.95)
			end
		end
	end
end

function Render.vertexNumbers__(render, bodies, context)

	local c = context
	local n = #bodies

	for i = 1, n do

		local parts = bodies[i].parts
		local p = #parts

		for k = p > 1 and 2 or 1, p do

			local part = parts[k]
			local v = #part.vertices

			for j = 1, v do
				c.fillStyle = 'rgba(255,255,255,0.2)'
				c.fillText(i + '_' + j, part.position.x + (part.vertices[j].x - part.position.x) * 0.8, part.position.y + (part.vertices[j].y - part.position.y) * 0.8)
			end
		end
	end
end

--[[
 * Renders mouse position.
 * @private
 * @method mousePosition
 * @param {render} render
 * @param {mouse} mouse
 * @param {RenderingContext} context
 ]]--

function Render.mousePosition(render, mouse, context)
end

--[[
 * Draws body bounds
 * @private
 * @method bodyBounds
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--
 function Render.bodyBounds(render, bodies, context)

	local engine = render.engine
	local options = render.options

	gfx.setLineWidth(1)
	gfx.setPattern({0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 170, 85, 170, 85, 170, 85, 170, 85})

	local n = #bodies

	for i = 1, n do
		local body = bodies[i]

		if (body.render.visible) then

			local parts = bodies[i].parts
			local p = #parts
			for j = p > 1 and 2 or 1, p do
				local part = parts[j]

				gfx.drawRect(part.bounds.min.x, part.bounds.min.y, part.bounds.max.x - part.bounds.min.x, part.bounds.max.y - part.bounds.min.y)
			end
		end
	end

	gfx.setColor(gfx.kColorBlack)
 end

function Render.bodyBounds__(render, bodies, context)

	local c = context
	local engine = render.engine
	local options = render.options

	c.beginPath()

	local n = #bodies

	for i = 1, n do
		local body = bodies[i]

		if (body.render.visible) then

			local parts = bodies[i].parts
			local p = #parts
			for j = p > 1 and 2 or 1, p do
				local part = parts[j]
				c.rect(part.bounds.min.x, part.bounds.min.y, part.bounds.max.x - part.bounds.min.x, part.bounds.max.y - part.bounds.min.y)
			end
		end
	end

	--[[
	if (options.wireframes) then
		c.strokeStyle = nil -- color
	else
		c.strokeStyle = nil -- color
	end
	]]--

	c.lineWidth = 1
	c.stroke()
end

--[[
 * Draws body angle indicators and axes
 * @private
 * @method bodyAxes
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--

 function Render.bodyAxes(render, bodies, context)

	local engine = render.engine
	local options = render.options
	local part,
		body,
		parts,
		vertices,
		p

	gfx.setPattern({0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 170, 85, 170, 85, 170, 85, 170, 85})

	for i = 1, #bodies do
		repeat

			body = bodies[i]
			parts = body.parts

			if (not body.render.visible) then
				break
			end

			p = #parts

			if (options.showAxes) then

				-- render all axes
				vertices = Table{}

				for j = p > 1 and 2 or 1, p do

					part = parts[j]

					for k = 1, #part.axes do
						local axis = part.axes[k]

						vertices:push(part.position.x)
								:push(part.position.y)
								:push(part.position.x + axis.x * 20)
								:push(part.position.y + axis.y * 20)
					end

					gfx.setLineWidth(1)
					gfx.drawPolygon(table.unpack(vertices))

				end
			else

				for j = p > 1 and 2 or 1, p do

					part = parts[j]

					vertices = Table{}

					for k = 1, #part.axes do

						-- render a single axis indicator
						vertices:push(part.position.x)
								:push(part.position.y)
								:push((part.vertices[1].x + part.vertices[#part.vertices].x) / 2)
								:push((part.vertices[1].y + part.vertices[#part.vertices].y) / 2)

					end

					gfx.setLineWidth(1)
					gfx.drawPolygon(table.unpack(vertices))

				end
			end

			break
		until true
	end

 end

function Render.bodyAxes__(render, bodies, context)

	local c = context
	local engine = render.engine
	local options = render.options
	local n = #bodies
	local part

	if (n > 0) then
		c.beginPath()
	end

	for i = 1, n do
		repeat

			local body = bodies[i]
			local parts = body.parts

			if (not body.render.visible) then
				break
			end

			local p = #parts

			if (options.showAxes) then
				-- render all axes

				for j = p > 1 and 2 or 1, p do
					part = parts[j]
					local a = #part.axes
					for k = 1, a do
						local axis = part.axes[k]
						c.moveTo(part.position.x, part.position.y)
						c.lineTo(part.position.x + axis.x * 20, part.position.y + axis.y * 20)
					end
				end
			else

				for j = p > 1 and 2 or 1, p do

					part = parts[j]
					local a = #part.axes

					for k = 1, a do
						-- render a single axis indicator
						c.moveTo(part.position.x, part.position.y)
						c.lineTo((part.vertices[0].x + part.vertices[part.vertices.length-1].x) / 2,
							(part.vertices[0].y + part.vertices[part.vertices.length-1].y) / 2)
					end
				end
			end
		break
		until true
	end

	if (n > 0) then

		if (options.wireframes) then
			-- c.strokeStyle = nil -- color
			c.lineWidth = 1
		else
			-- c.strokeStyle = nil -- color
			c.globalCompositeOperation = 'overlay'
			c.lineWidth = 2
		end

		c.stroke()
		c.globalCompositeOperation = 'source-over'

	end

end

--[[
 * Draws body positions
 * @private
 * @method bodyPositions
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--
function Render.bodyPositions(render, bodies, context)

	local c = context
	local engine = render.engine
	local options = render.options
	local body,
		part

	c.beginPath()

	-- render current positions
	local n = #bodies
	for i = 1, n do
		repeat
			body = bodies[i]

			if (not body.render.visible) then
				break
			end
			-- handle compound parts
			local p = #body.parts
			for k = 1, p do
				part = body.parts[k]
				c.arc(part.position.x, part.position.y, 3, 0, 2 * math.pi, false)
				c.closePath()
			end
		break
		until true
	end

	--[[
	if (options.wireframes) then
		c.fillStyle = nil -- color
	else
		c.fillStyle = nil -- color
	end
	]]--
	c.fill()

	c.beginPath()

	-- render previous positions

	for i = 1, n do
		body = bodies[i]
		if (body.render.visible) then
			c.arc(body.positionPrev.x, body.positionPrev.y, 2, 0, 2 * math.pi, false)
			c.closePath()
		end
	end

	-- c.fillStyle = nil -- color
	c.fill()
end

--[[
 * Draws body velocity
 * @private
 * @method bodyVelocity
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--
 function Render.bodyVelocity(render, bodies, context)

	local n = #bodies

	for i = 1,  n do
		repeat
			local body = bodies[i]

			if (not body.render.visible) then
				break
			end
			gfx.setLineWidth(3)
			gfx.drawLine(body.position.x,
						body.position.y,
						body.position.x + (body.position.x - body.positionPrev.x) * 2,
						body.position.y + (body.position.y - body.positionPrev.y) * 2)
		break
		until true
	end

 end

function Render.bodyVelocity__(render, bodies, context)

	local c = context

	c.beginPath()

	local n = #bodies

	for i = 1,  n do
		repeat
			local body = bodies[i]

			if (not body.render.visible) then
				break
			end
			c.moveTo(body.position.x, body.position.y)
			c.lineTo(body.position.x + (body.position.x - body.positionPrev.x) * 2, body.position.y + (body.position.y - body.positionPrev.y) * 2)
		break
		until true
	end

	c.lineWidth = 3
	-- c.strokeStyle = nil -- color
	c.stroke()
end

--[[
 * Draws body ids
 * @private
 * @method bodyIds
 * @param {render} render
 * @param {body[]} bodies
 * @param {RenderingContext} context
 ]]--

 function Render.bodyIds(render, bodies, context)

	local n = #bodies

	for i = 1, n do
		repeat

			if (not bodies[i].render.visible) then
				break
			end

			local parts = bodies[i].parts
			local p = #parts
			for j = p > 1 and 2 or 1, p do
				local part = parts[j]
				gfx.drawText(part.id, part.position.x + 15, part.position.y - 30)
			end
			break
		until true
	end
 end

function Render.bodyIds__(render, bodies, context)

	local c = context
	local n = #bodies

	for i = 1, n do
		repeat

			if (not bodies[i].render.visible) then
				break
			end

			local parts = bodies[i].parts
			local p = #parts
			for j = p > 1 and 2 or 1, p do
				local part = parts[j]
				-- c.fillStyle = nil -- color
				c.fillText(part.id, part.position.x + 10, part.position.y - 10)
			end
		break
		until true
	end
end

--[[
 * Description
 * @private
 * @method collisions
 * @param {render} render
 * @param {pair[]} pairs
 * @param {RenderingContext} context
 ]]--

 function Render.collisions(render, pairs, context)

	-- print('Render.collisions', #pairs)

	local options = render.options

	local pair,
			collision,
			corrected,
			bodyA,
			bodyB

	-- render collision positions
	local p = #pairs

	for i = 1, p do
		repeat
			pair = pairs[i]

			if (not pair.isActive) then
				break
			end

			collision = pair.collision
			local c = #pair.activeContacts

			for j = 1, c do
				local contact = pair.activeContacts[j]
				local vertex = contact.vertex

				gfx.setColor(gfx.kColorBlack)
				gfx.fillRect(vertex.x - 2, vertex.y - 2, 4, 4)
			end
			break
		until true
	end

	-- do return end

	-- render collision normals

	for i = 1, p do
		repeat

			local vertices = Table{}
			pair = pairs[i]

			if (not pair.isActive) then
				break
			end

			collision = pair.collision

			if (#pair.activeContacts > 0) then
				local normalPosX = pair.activeContacts[1].vertex.x
				local normalPosY = pair.activeContacts[1].vertex.y

				if (#pair.activeContacts == 2) then
					normalPosX = (pair.activeContacts[1].vertex.x + pair.activeContacts[2].vertex.x) / 2
					normalPosY = (pair.activeContacts[1].vertex.y + pair.activeContacts[2].vertex.y) / 2
				end

				if (collision.bodyB == collision.supports[1].body or collision.bodyA.isStatic) then

					vertices:push(normalPosX - collision.normal.x * 8)
							:push(normalPosY - collision.normal.y * 8)
				else
					vertices:push(normalPosX + collision.normal.x * 8)
							:push(normalPosY + collision.normal.y * 8)
				end

				vertices:push(normalPosX)
						:push(normalPosY)
			end

			if #vertices > 0 then
				gfx.setLineWidth(2)
				gfx.drawPolygon(table.unpack(vertices))
			end

			break
		until true
	end
 end

function Render.collisions__(render, pairs, context)
	local c = context
	local options = render.options

	local pair,
		collision,
		corrected,
		bodyA,
		bodyB

	c.beginPath()

	-- render collision positions
	local p = #pairs

	for i = 1, p do
		repeat
			pair = pairs[i]

			if (not pair.isActive) then
				break
			end

			collision = pair.collision
			local c = #pair.activeContacts

			for j = 1, c do
				local contact = pair.activeContacts[j]
				local vertex = contact.vertex
				c.rect(vertex.x - 1.5, vertex.y - 1.5, 3.5, 3.5)
			end
		break
		until true
	end

	--[[
	if (options.wireframes) then
		c.fillStyle = nil -- color
	else
		c.fillStyle = nil -- color
	end
	]]--

	c.fill()

	c.beginPath()

	-- render collision normals

	for i = 1, p do
		repeat

			pair = pairs[i]

			if (not pair.isActive) then
				break
			end

			collision = pair.collision

			if (pair.activeContacts.length > 0) then
				local normalPosX = pair.activeContacts[0].vertex.x
				local normalPosY = pair.activeContacts[0].vertex.y

				if (pair.activeContacts.length == 2) then
					normalPosX = (pair.activeContacts[0].vertex.x + pair.activeContacts[1].vertex.x) / 2
					normalPosY = (pair.activeContacts[0].vertex.y + pair.activeContacts[1].vertex.y) / 2
				end

				if (collision.bodyB == collision.supports[0].body or collision.bodyA.isStatic == true) then
					c.moveTo(normalPosX - collision.normal.x * 8, normalPosY - collision.normal.y * 8)
				else
					c.moveTo(normalPosX + collision.normal.x * 8, normalPosY + collision.normal.y * 8)
				end

				c.lineTo(normalPosX, normalPosY)
			end

		break
		until true
	end

	--[[
	if (options.wireframes) then
		c.strokeStyle = nil -- color
	else
		c.strokeStyle = nil -- color
	end
	]]--

	c.lineWidth = 1
	c.stroke()
end

--[[
 * Description
 * @private
 * @method separations
 * @param {render} render
 * @param {pair[]} pairs
 * @param {RenderingContext} context
 ]]--

function Render.separations(render, pairs, context)

	local c = context
	local options = render.options
	local pair,
		collision,
		corrected,
		bodyA,
		bodyB

	c.beginPath()

	-- render separations
	local n = #pairs

	for i = 1, p do
		repeat

			pair = pairs[i]

			if (not pair.isActive) then
				break
			end

			collision = pair.collision
			bodyA = collision.bodyA
			bodyB = collision.bodyB

			local k = 1

			if (not bodyB.isStatic and not bodyA.isStatic) then
				k = 0.5
			end

			if (bodyB.isStatic) then
				k = 0
			end

			c.moveTo(bodyB.position.x, bodyB.position.y)
			c.lineTo(bodyB.position.x - collision.penetration.x * k, bodyB.position.y - collision.penetration.y * k)

			k = 1

			if (not bodyB.isStatic and not bodyA.isStatic) then
				k = 0.5
			end

			if (bodyA.isStatic) then
				k = 0
			end

			c.moveTo(bodyA.position.x, bodyA.position.y)
			c.lineTo(bodyA.position.x + collision.penetration.x * k, bodyA.position.y + collision.penetration.y * k)
		break
		until true
	end

	--[[
	if (options.wireframes) then
		c.strokeStyle = nil -- color
	else
		c.strokeStyle = nil -- color
	end
	]]--

	c.stroke()
end

--[[
 * Description
 * @private
 * @method grid
 * @param {render} render
 * @param {grid} grid
 * @param {RenderingContext} context
 ]]--

 function Render.grid(render, grid, context)

	local options = render.options
	local bucketKeys = Common.keys(grid.buckets)
	local bucketWidth = grid.bucketWidth
	local bucketHeight = grid.bucketHeight
	local n = #bucketKeys

	gfx.setLineWidth(1)
	gfx.setPattern({0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 170, 85, 170, 85, 170, 85, 170, 85})

	for i = 1, n do
		repeat

			local bucketId = bucketKeys[i]

			if (#grid.buckets[bucketId] < 2) then
				break
			end

			local region = {}

			for val1, val2 in bucketId:gmatch('C(.*)R(.*)') do
				table.insert(region, val1)
				table.insert(region, val2)
			end

			-- if (#region > 0 and tonumber(region[1]) and tonumber(region[2])) then

				gfx.drawRect(	0.5 + tonumber(region[1]) * bucketWidth,
								0.5 + tonumber(region[2]) * bucketHeight,
								bucketWidth,
								bucketHeight)

				if options.showGridId then
					gfx.drawText(bucketId,
								0.5 + tonumber(region[1]) * bucketWidth + 5,
								0.5 + tonumber(region[2]) * bucketHeight + 5)
				end

			-- end

			break
		until true
	end

end

--[[
function Render.grid__(render, grid, context)

	local c = context
	local options = render.options

	if (options.wireframes) then
		c.strokeStyle = 'rgba(255,180,0,0.1)'
	else
		c.strokeStyle = 'rgba(255,180,0,0.5)'
	end

	c.beginPath()

	local bucketKeys = Common.keys(grid.buckets)
	local n = #bucketKeys

	for i = 1, n do
		repeat

			local bucketId = bucketKeys[i]

			if (#grid.buckets[bucketId] < 2) then
				break
			end

			-- local region = bucketId:split('/C|R/')

			local region = {}

			for val1, val2 in bucketId:gmatch('C(.*)R(.*)') do
				table.insert(region, val1)
				table.insert(region, val2)
			end

			c.rect(0.5 + parseInt(region[1], 10) * grid.bucketWidth,
				0.5 + parseInt(region[2], 10) * grid.bucketHeight,
				grid.bucketWidth,
				grid.bucketHeight)
		break
		until true
	end

	c.lineWidth = 1
	c.stroke()
end
]]--

--[[
 * Description
 * @private
 * @method inspector
 * @param {inspector} inspector
 * @param {RenderingContext} context
 ]]--

function Render.inspector(inspector, context)

	local engine = inspector.engine
	local selected = inspector.selected
	local render = inspector.render
	local options = render.options
	local bounds

	if (options.hasBounds) then
		local boundsWidth = render.bounds.max.x - render.bounds.min.x
		local boundsHeight = render.bounds.max.y - render.bounds.min.y
		local boundsScaleX = boundsWidth / render.options.width
		local boundsScaleY = boundsHeight / render.options.height

		context.scale(1 / boundsScaleX, 1 / boundsScaleY)
		context.translate(-render.bounds.min.x, -render.bounds.min.y)
	end

	local n = #selected

	for i = 1, n do

		local item = selected[i].data

		context.translate(0.5, 0.5)
		context.lineWidth = 1
		-- context.strokeStyle = nil -- color
		-- context.setLineDash({1,2})

		if (item.type == 'body') then
				-- render body selections
				bounds = item.bounds
				context.beginPath()
				context.rect(Math.floor(bounds.min.x - 3), math.floor(bounds.min.y - 3),
					math.floor(bounds.max.x - bounds.min.x + 6), math.floor(bounds.max.y - bounds.min.y + 6))
				context.closePath()
				context.stroke()

		elseif (item.type == 'constraint') then

				-- render constraint selections
				local point = item.pointA

				if (item.bodyA) then
					point = item.pointB
				end

				context.beginPath()
				context.arc(point.x, point.y, 10, 0, 2 * math.pi)
				context.closePath()
				context.stroke()
		end

		context.setLineDash({})
		context.translate(-0.5, -0.5)
	end

	-- render selection region
	if (inspector.selectStart ~= nil) then
		context.translate(0.5, 0.5)
		context.lineWidth = 1
		-- context.strokeStyle = nil -- color
		-- context.fillStyle = nil -- color
		bounds = inspector.selectBounds
		context.beginPath()
		context.rect(math.floor(bounds.min.x), math.floor(bounds.min.y),
			math.floor(bounds.max.x - bounds.min.x), math.floor(bounds.max.y - bounds.min.y))
		context.closePath()
		context.stroke()
		context.fill()
		context.translate(-0.5, -0.5)
	end

	if (options.hasBounds) then
		context.setTransform(1, 0, 0, 1, 0, 0)
	end
end


--[[
*
*  Events Documentation
*
]]--

--[[
* Fired before rendering
*
* @event beforeRender
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired after rendering
*
* @event afterRender
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
*
*  Properties Documentation
*
]]--

--[[
 * A back-reference to the `Matter.Render` module.
 *
 * @property controller
 * @type render
 ]]--

--[[
 * A reference to the `Matter.Engine` instance to be used.
 *
 * @property engine
 * @type engine
 ]]--

--[[
 * A reference to the element where the canvas is to be inserted (if `render.canvas` has not been specified)
 *
 * @property element
 * @type HTMLElement
 * @default nil
 ]]--

--[[
 * The canvas element to render to. If not specified, one will be created if `render.element` has been specified.
 *
 * @property canvas
 * @type HTMLCanvasElement
 * @default nil
 ]]--

--[[
 * The configuration options of the renderer.
 *
 * @property options
 * @type {}
 ]]--

--[[
 * The target width in pixels of the `render.canvas` to be created.
 *
 * @property options.width
 * @type number
 * @default 800
 ]]--

--[[
 * The target height in pixels of the `render.canvas` to be created.
 *
 * @property options.height
 * @type number
 * @default 600
 ]]--

--[[
 * A flag that specifies if `render.bounds` should be used when rendering.
 *
 * @property options.hasBounds
 * @type boolean
 * @default false
 ]]--

--[[
 * A `Bounds` object that specifies the drawing view region.
 * Rendering will be automatically transformed and scaled to fit within the canvas size (`render.options.width` and `render.options.height`).
 * This allows for creating views that can pan or zoom around the scene.
 * You must also set `render.options.hasBounds` to `true` to enable bounded rendering.
 *
 * @property bounds
 * @type bounds
 ]]--

--[[
 * The 2d rendering context from the `render.canvas` element.
 *
 * @property context
 * @type CanvasRenderingContext2D
 ]]--

--[[
 * The sprite texture cache.
 *
 * @property textures
 * @type {}
 ]]--
