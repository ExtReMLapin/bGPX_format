assert(bit, "bit lib is required")
local ffi = require("ffi")
local TEST = false
local gpxTestFile = "Track.gpx"
local bGPXFileName = "Track.bGPX"
local USE_DOUBLE_PRECISION = false

local function writeInt32(file, integer)
	local bytes = ffi.string(ffi.new("int[1]", integer), 4)
	file:write(bytes)
end

local function readInt32(file)
	local bytes = file:read(4)

	return ffi.cast("int*", ffi.new("char[4]", bytes))[0]
end

local function writeFloat(file, float)
	local bytes

	if USE_DOUBLE_PRECISION then
		bytes = ffi.string(ffi.new("double[1]", float), 8)
	else
		bytes = ffi.string(ffi.new("float[1]", float), 4)
	end

	file:write(bytes)
end

local function readFloat(file)
	if USE_DOUBLE_PRECISION then
		local bytes = file:read(8)

		return ffi.cast("double*", ffi.new("char[8]", bytes))[0]
	else
		local bytes = file:read(4)

		return ffi.cast("float*", ffi.new("char[4]", bytes))[0]
	end
end

local enum_displayColor = {
	"Black",
	"DarkRed",
	"DarkGreen",
	"DarkYellow",
	"DarkBlue",
	"DarkMagenta",
	"DarkCyan",
	"LightGray",
	"DarkGray",
	"Red",
	"Green",
	"Yellow",
	"Blue",
	"Magenta",
	"Cyan",
	"White",
	"Transparent"
}

for k, v in ipairs(enum_displayColor) do
	enum_displayColor[v] = k
end

--[[
	Uint32 time
	[float/double] minlat
	[float/double] maxlat
	[float/double] minlon
	[float/double] maxlon
	char* name
	byte enum_displayColor
	Uint32 countData
		... [float/double] latitude
		... [float/double] longitude
]]
function decompressBGPX(fileName)
	local fileHandle = assert(io.open(fileName, "rb"), "Cannot read file " .. fileName)

	local data = {
		time = readInt32(fileHandle),
		minlat = readFloat(fileHandle),
		maxlat = readFloat(fileHandle),
		minlon = readFloat(fileHandle),
		maxlon = readFloat(fileHandle)
	}

	local nameTbl = {}

	while true do
		local readByte = assert(fileHandle:read(1), "cannot read name from file")
		if readByte == "\0" then break end
		table.insert(nameTbl, readByte)
	end

	data.name = table.concat(nameTbl)
	data.enum_displayColor = enum_displayColor[string.byte(fileHandle:read(1))]
	local count = readInt32(fileHandle)
	local i = 0
	data.coordsList = {}

	while i < count do
		table.insert(data.coordsList, {
			latitude = readFloat(fileHandle),
			longitude = readFloat(fileHandle)
		})

		i = i + 1
	end

	fileHandle:close()

	return data
end

local function compressToBGPX(data, fileName)
	local fileHandle = assert(io.open(fileName, "wb"), "Cannot write file " .. fileName)
	writeInt32(fileHandle, data.time)
	writeFloat(fileHandle, data.minlat)
	writeFloat(fileHandle, data.maxlat)
	writeFloat(fileHandle, data.minlon)
	writeFloat(fileHandle, data.maxlon)
	fileHandle:write(data.name .. '\0')
	fileHandle:write(string.char(enum_displayColor[data.enum_displayColor]))
	writeInt32(fileHandle, #data.coordsList)

	for k, curPos in ipairs(data.coordsList) do
		writeFloat(fileHandle, curPos.latitude)
		writeFloat(fileHandle, curPos.longitude)
	end

	fileHandle:close()
end

local function parseMetaData(strData)
	local strTime = string.match(strData, "%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ")
	local intTime

	do
		intTime = os.time({
			year = strTime:sub(1, 4),
			month = strTime:sub(6, 7),
			day = strTime:sub(9, 10),
			hour = strTime:sub(12, 13),
			min = strTime:sub(15, 16),
			sec = strTime:sub(18, 19)
		})
	end

	local minlat = tonumber(string.match(strData, "minlat=\"(.-)\""))
	local maxlat = tonumber(string.match(strData, "maxlat=\"(.-)\""))
	local minlon = tonumber(string.match(strData, "minlon=\"(.-)\""))
	local maxlon = tonumber(string.match(strData, "maxlon=\"(.-)\""))

	return intTime, minlat, maxlat, minlon, maxlon
end

function parseGPXTrack(fileName)
	local fileHandle = assert(io.open(fileName, "r"), "Cannot read file " .. fileName)
	local fileData = fileHandle:read("*all")
	local metadata = string.match(fileData, "<metadata>(.-)</metadata>")
	local time, minlat, maxlat, minlon, maxlon = parseMetaData(metadata)
	local name = string.match(fileData, "<name>(.-)</name>")
	local color = string.match(fileData, "<gpxx:DisplayColor>(.-)</gpxx:DisplayColor>")
	local coordsList = {}

	for coord in string.gmatch(fileData, "<trkpt(.-)/>") do
		table.insert(coordsList, {
			latitude = tonumber(coord:match("lat=\"(.-)\"")),
			longitude = tonumber(coord:match("lon=\"(.-)\""))
		})
	end

	fileHandle:close()

	return {
		time = time,
		minlat = minlat,
		maxlat = maxlat,
		minlon = minlon,
		maxlon = maxlon,
		name = name,
		enum_displayColor = color,
		coordsList = coordsList
	}
end

------------------------------------
---------------TESTS----------------
------------------------------------
if not TEST then return end

local testTable = {
	time = os.time(),
	minlat = 0,
	maxlat = 0,
	minlon = 666.3334242,
	maxlon = 666.666,
	name = "ceci est un titre",
	enum_displayColor = "Blue",
	coordsList = {
		{
			longitude = 1337.5464654456456498456,
			latitude = 444
		},
		{
			longitude = 134537,
			latitude = 446.4564564564
		}
	}
}

local function compareNumber(a, b)
	return math.abs(a - b) < 0.00005
end

function table_eq(table1, table2)
	local avoid_loops = {}

	local function recurse(t1, t2)
		-- compare value types
		local t1Type = type(t1)
		local t2Type = type(t2)
		if t1Type ~= t2Type then return false, string.format("type error : expected %s but got %s", t1Type, t2Type) end

		-- Base case: compare simple values
		if t1Type ~= "table" then
			if t1Type == "number" then
				return compareNumber(t1, t2), string.format("Number comp fail, expected %f, got %f", t1, t2)
			else
				return t1 == t2, string.format("%s %s", tostring(t1), tostring(t2))
			end
		end

		-- Now, on to tables.
		-- First, let's avoid looping forever.
		if avoid_loops[t1] then return avoid_loops[t1] == t2 end
		avoid_loops[t1] = t2
		-- Copy keys from t2
		local t2keys = {}
		local t2tablekeys = {}

		for k, _ in pairs(t2) do
			if type(k) == "table" then
				table.insert(t2tablekeys, k)
			end

			t2keys[k] = true
		end

		-- Let's iterate keys from t1
		for k1, v1 in pairs(t1) do
			local v2 = t2[k1]

			if type(k1) == "table" then
				-- if key is a table, we need to find an equivalent one.
				local ok = false

				for i, tk in ipairs(t2tablekeys) do
					if table_eq(k1, tk) and recurse(v1, t2[tk]) then
						table.remove(t2tablekeys, i)
						t2keys[tk] = nil
						ok = true
						break
					end
				end

				if not ok then return false, "not okay" end
			else
				-- t1 has a key which t2 doesn't have, fail.
				if v2 == nil then return false, string.format("missing key : %s from t2", k1) end
				t2keys[k1] = nil
				local result, message = recurse(v1, v2)
				if not result then return false, message end
			end
		end

		-- if t2 has a key which t1 doesn't have, fail.
		if next(t2keys) then return false, string.format("missing key : %s from t1", k2) end

		return true, "Success"
	end

	return recurse(table1, table2)
end

compressToBGPX(testTable, bGPXFileName)
local outTable = decompressBGPX(bGPXFileName)
local compSuccess, message = table_eq(outTable, testTable)

if compSuccess then
	print("First Integrity check okay")
else
	print("INTEGRITY FAIL", message)
end

print(string.format("precision is %f ", math.abs(testTable.coordsList[1].longitude - outTable.coordsList[1].longitude)))
local tbl = parseGPXTrack(gpxTestFile)
compressToBGPX(tbl, bGPXFileName)
outTable = decompressBGPX(bGPXFileName)
compSuccess, message = table_eq(outTable, tbl)

if compSuccess then
	print("Second Integrity check okay")
else
	print("INTEGRITY FAIL", message)
end

print(string.format("precision is %f ", math.abs(tbl.coordsList[1].longitude - outTable.coordsList[1].longitude)))

local function fsize(file)
	local current = file:seek() -- get current position
	local size = file:seek("end") -- get file size
	file:seek("set", current) -- restore position

	return size
end

local fileHandle = io.open(gpxTestFile, "rb")
local gpxSize = fsize(fileHandle)
fileHandle:close()
fileHandle = io.open(bGPXFileName, "rb")
local bGPXSize = fsize(fileHandle)
fileHandle:close()
print(bGPXSize, gpxSize)
print(string.format("Percentage gain : %f%%", (gpxSize / bGPXSize) * 100))
