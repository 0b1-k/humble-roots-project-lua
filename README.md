**Summary**

The Humble Roots Project is a grow room automation control system designed for stable non-stop operation. It is managed through a single configuration file and can communicate with an administrator over SMS text messages. Data visualization is provided in the form of Grafana dashboards powered by InfluxDB.

**Dependencies**

Any platform capable of running Lua + sockets + file system support. Tested under Ubunt 16, 17 and Raspbian.

***CMake***

```
sudo apt-get install cmake build-essential
```

***Git***

```
sudo apt-get install git
```

***LuaDist***

Install [LuaDist](http://luadist.org/) in the home folder.

***Humble Roots Project***

```
cd ~
git clone https://github.com/fabienroyer/humble-roots-project-lua.git
cd humble-roots-project-lua
cp -R * ~/LuaDist/share


# Compile the Serial Communication Library
cd ~/LuaDist/share/lua-serial
make

# Copy the library to the project folder. For 32-bit platforms:
cp ./build/lin32/libserial.so ~/LuaDist/share/weed/lua
# or 64-bit platforms
cp ./build/lin64/libserial.so ~/LuaDist/share/weed/lua

# Compile the SMS PDU encoding / decoding library
cd ~/LuaDist/share/smspdu
make

# Copy the library to the project folder. For 32-bit platforms
cp ./build/lin32/smspdu.so ~/LuaDist/share/weed/lua
# or 64-bit platforms
cp ./build/lin64/smspdu.so ~/LuaDist/share/weed/lua

# Copy the template config file to a usable .toml config file
cd ~/LuaDist/share/weed/config
mv config.tpl config.toml
cd ..
# Start the project
./../../bin/lua control.lua
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


[INFO  14:15:30] control.lua:180: Copyright (c) 2017 Fabien Royer
[INFO  14:15:30] control.lua:185: Gateway started
[INFO  14:15:30] ./listener.lua:17: TCP listener @ ::1:42024
[DEBUG 14:15:31] control.lua:172: Replay node=2&rssi=-43&t=srh&bat=4.77&low=0&pwr=1&p=1
[DEBUG 14:15:32] control.lua:172: Replay node=20&rssi=-31&t=rly&bat=5.00&low=0&pwr=1&r=4&s=1
[DEBUG 14:15:33] control.lua:172: Replay node=20&rssi=-31&t=rly&bat=5.00&low=0&pwr=1&r=5&s=1
[DEBUG 14:15:34] control.lua:172: Replay node=20&rssi=-30&t=rly&bat=5.00&low=0&pwr=1&r=5&s=1
[DEBUG 14:15:35] control.lua:172: Replay node=40&rssi=-44&t=clm&bat=3.78&low=0&pwr=0&tmp=24.58&rh=55
...
```

***InfluxDB***

All sensor data is logged to [influxdb](https://influxdata.com/time-series-platform/influxdb/).
Once influxdb is installed, create a 'sensors' and an 'events' database, then enable influxdb logging in ./config/config.toml. See /weed/config/influxdb-udp.conf for a ready to use config snippet for communicating with InfluxDB over UDP (recommended over HTTP).

***Grafana***

Uses Grafana to plot sensor data. Once Grafana is installed, configure it to use the Influxdb instance previously installed and import the
Humble Roots Project dashboard from ./dashboard/grafana/Lab.json.


