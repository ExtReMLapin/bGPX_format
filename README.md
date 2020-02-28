# bGPX_format
**B**inary garmin Tracks **GPX** Format to optimize space on GPS with low memory

**Only meant to be used with tracks but it can be edited to works with routes**

GPX is a XML based file format used to store GPS coordinates in GPS devices.

The issue is some GPSs, have very low memory, the Foretrex 601 for example has only 8mb of memory.

Storing a 500km track takes around **1.633Mb** out of **8 available Mb** on the device.

If storing it in a bGPX format the track takes only **197Kb** (832% gain)

Using double precision mode it takes **393Kb** (416% gain)

![](https://i.imgur.com/LkLE74g.png)

The storage is very simple
```C
	UInt32 time
	[float/double] minlat
	[float/double] maxlat
	[float/double] minlon
	[float/double] maxlon
	char* name
	byte enum_displayColor
	UInt32 countData
		... [float/double] latitude
		... [float/double] longitude
  ```
  
  
  
  # Usage and requirements
  
  It requires LuaJIT as it uses FFI api to write integers/floats/doubles directly in the file.
  
  ## `parseGPXTrack(fileName)` 
  Parses a GPX file to store it in the intermediate data model
  
  ```Lua
  parseGPXTrack("file.gpx")
  ```
  
  
 ## `compressToBGPX(dataTable, fileName)`
 Stores the intermediate data representation to a binary GPX format
   ```Lua
  parseGPXTrack(data, "file.bGPX")
  ```
  
  
  
  #Possible improvements
  
* Getting rid of the waypoints count as there is no data after the waypoints/coords list.
* Generating the min/max len/lon on the fly (would save a very little memory to eat more CPU time as it would require to look thru all the list)
