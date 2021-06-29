
Test = {}
Test.__index = Test

function Test:new(name)

	local self = {}
	setmetatable(self, metatable)

	self.name = name
	self.step = 0
	self.complete = true

	print('Start test: ' .. name)

	function self:equal(a, b)

		if (a == b) then
			self:_print('+ is equal')
		else
			self:_print(' - is not equal (' .. a .. ' ~= ' .. b .. ')')
		end

		if 	(a ~= b) then
			self.complete = false
		end
	end

	function self:ok(val)
		if(val) then
			self:_print('+ ok')
		else
			self:_print('- not ok (' .. (val and 'true' or 'false')  .. ')')
		end
		if (not val) then
			self.complete = false
		end
	end

	function self:done()
		if	self.complete then
			print('> test complete')
		else
			print('> test is not complete')
		end
	end

	function self:_print(message)
		self.step += 1
		print(self.step, message)
	end

	return self
end