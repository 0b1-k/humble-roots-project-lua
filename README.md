**Dependencies**

***Raspbian Jessie Lite***

https://www.raspberrypi.org/downloads/raspbian/

***CMake***

```
sudo apt-get install cmake build-essential
```

***Git***

```
sudo apt-get install git
```

***LuaDist***

Install (LuaDist)[http://luadist.org/].

Install the LuaDist packages required by the Humble Roots Project:

```
./LuaDist/bin/luadist install dkjson
./LuaDist/bin/luadist install md5
```

***Humble Roots Project***

```
	cd ~
	git clone https://github.com/fabienroyer/humble-roots-project-lua.git
	cd humble-roots-project-lua
	cp -R * ~/LuaDist/share
	cd ~/LuaDist/share/lua-serial
	mkdir build/lin32
	make
	cp ./src/serial.lua ~/LuaDist/lib/lua
	cp ./build/lin32/libserial.so ~/LuaDist/lib/lua
	cd ~/LuaDist/share/weed/config
	mv config.tpl config.json
	cd ..
	sudo ./../../bin/lua control.lua
```

On startup, the project will show a console output like this:

```
[TRACE 14:15:30] ./replay.lua:14: Replay data lines: 713
[INFO  14:15:30] control.lua:178: The Humble Roots Project
[INFO  14:15:30] control.lua:179: 
			                  |
			                 |.|
			                 |.|
			                |\./|
			                |\./|
			.               |\./|               .
			 \^.\          |\\.//|          /.^/
			  \--.|\       |\\.//|       /|.--/
			    \--.| \    |\\.//|    / |.--/
			     \---.|\    |\./|    /|.---/
			        \--.|\  |\./|  /|.--/
			           \ .\  |.|  /. /
			 _ -_^_^_^_-  \ \\ // /  -_^_^_^_- _
			   - -/_/_/- ^ ^  |  ^ ^ -\_\_\- -
					  |


[INFO  14:15:30] control.lua:180: Copyright (c) 2016 Fabien Royer
[INFO  14:15:30] control.lua:185: Gateway started
[INFO  14:15:30] ./listener.lua:17: HTTP listener @ ::1:42024
[DEBUG 14:15:31] control.lua:172: Replay node=2&rssi=-43&t=srh&bat=4.77&low=0&pwr=1&p=1
[DEBUG 14:15:32] control.lua:172: Replay node=20&rssi=-31&t=rly&bat=5.00&low=0&pwr=1&r=4&s=1
[DEBUG 14:15:33] control.lua:172: Replay node=20&rssi=-31&t=rly&bat=5.00&low=0&pwr=1&r=5&s=1
[DEBUG 14:15:34] control.lua:172: Replay node=20&rssi=-30&t=rly&bat=5.00&low=0&pwr=1&r=5&s=1
[DEBUG 14:15:35] control.lua:172: Replay node=40&rssi=-44&t=clm&bat=3.78&low=0&pwr=0&tmp=24.58&rh=55
...
```

***InfluxDB***

The Humble Roots Project logs all sensor data to (influxdb)[https://influxdata.com/time-series-platform/influxdb/].
Once influxdb is installed, create a 'sensors' database and enable influxdb logging in ./config/config.json.

***Grafana***

The Humble Roots Project uses Grafana to plot sensor data.
Once Grafana is installed, configure it to use the influxdb instance previously installed and import the
Humble Roots Project dashboard from ./dashboard/grafana/Lab.json.

***smsd***

The Humble Roots Project relies on (smsd)[http://smstools3.kekekasvi.com/] to send and receive SMS notifications if enabled.
Once smsd is installed, enable it in ./config/config.json.

