-- Matter
import 'matter/matter'

print('Common.extend')

local x = 123

local a = {
	abc = x
}

local b = {
	abc = 456
}

local c = {
	xxx = true
}

local d = {'a', 'b', 'c', a, 'd'}

Common.extend(a, b, c)

printTable(a)


print('Common.clone')
local a2 = Common.clone(a, true)
print(a2 == a)


print('Common.keys')
local k = Common.keys(a2)
printTable(k)

print('Common.values')
local k2 = Common.values(a2)
printTable(k2)

print('Common.isArray')
print(Common.isArray(a))
print(Common.isArray(123))

print('Common.clamp')
print(Common.clamp(45, 2, 10))
print(Common.clamp(15, -9, 0))

print('Common.sign')
print(Common.sign(-3))
print(Common.sign(3))

print('Common.random')
print(Common.random(4, 22))

print('Common.nextId')
print(Common.nextId())
print(Common.nextId())
print(Common.nextId())

print('Common.indexOf')
print(Common.indexOf(a, x))
print(Common.indexOf(d, 'b'))
print(Common.indexOf(d, a))


