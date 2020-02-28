# bGPX_format
**B**inary garmin Tracks **GPX** Format to optimize space on GPS with low memory


GPX is a XML based file format used to store GPS coordinates in GPS devices.

The issue is some GPSs, have very low memory, the Foretrex 601 for example has only 8mb of memory.

Storing a 500km route takes around **1.633Mb** out of **8 available Mb** on the device.

If storing it in a bGPX format the route takes only **197Kb** (832% gain)

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
  
  
