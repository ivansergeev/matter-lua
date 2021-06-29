
-- To fixed
function tofixed(n, length)
	return tonumber(string.format("%." .. length .. "f", n))
end
