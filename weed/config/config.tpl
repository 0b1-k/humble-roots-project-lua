{
  "log": {
    "level": "trace",
    "file": "./logs/hroots.log"
  },
  "replay": {
    "enabled": true,
    "record": false,
    "recordDuration": 3600
  },
  "serial": {
    "enabled": false,
    "port": "/dev/ttyUSB0",
    "baudrate": 115200
  },
  "influxDB": {
    "enabled": false,
    "host": "localhost",
    "port": 8086,
    "db": "sensors"
  },
  "sms": {
    "enabled": false,
    "accept": "19995551212",
    "dest": "19995551212",
    "outgoing": "/var/spool/sms/outgoing",
    "incoming": "/var/spool/sms/incoming"
  },
  "shell": {
    "enabled": true,
    "bind": "localhost",
    "port": 42024
  },
  "node": {
    "2": "plant",
    "4": "sump",
    "20": "relay",
    "30": "tank",
    "40": "climate",
    "50": "valve",
    "60": "plant.top",
    "plant": "2",
    "sump": "4",
    "relay": "20",
    "tank": "30",
    "climate": "40",
    "valve": "50",
    "plant.top", "60"
  },
  "r":	{
    "0": "dh",
    "1": "drain",
    "2": "vent",
    "3": "water",
    "4": "light",
    "5": "air",
    "dh": "0",
    "drain": "1",
    "vent": "2",
    "water": "3",
    "light": "4",
    "air": "5"
  },
  "v":	{
    "0": "filter",
    "1": "v1",
    "2": "v2",
    "3": "v3",
    "4": "v4",
    "5": "v5",
    "6": "v6",
    "7": "v7",
    "filter": "0",
    "v1": "1",
    "v2": "2",
    "v3": "3",
    "v4": "4",
    "v5": "5",
    "v6": "6",
    "v7": "7"
  },
  "s":	{
    "0": "off",
    "1": "on",
    "off": "0",
    "on": "1"
  },
  "tx":	{
    "nak": "0",
    "ack": "1",
    "0": "nak",
    "1": "ack"
  },
  "fixup": {
    "s": {
      "off": 0,
      "on": 1
      }
  },
  "control": {
    "tick": {"freqSec": 15},
    "nodeTimeout": {
      "freqSec": 240,
      "title": "Heartbeat timeout",
      "rebootAfter": 600,
      "rebootMsg": "Fatal heartbeat failure. Rebooting!"
    },
    "signal": [{
      "enabled": true,
      "value": "rssi",
      "alert": {"op": "<", "setpoint": -80.0, "title": "Low signal strength alert"}
    }],
    "srh": [{
      "enabled": true,
      "node": "plant.top",
      "value": "p",
      "time": {"from": "18:50", "to": "19:05", "days": {"sun", "tue", "thu"}},
      "on":  {"op": "<=", "setpoint": 100.0, "cmd": "-n relay -r water -s on"}
    },{
      "enabled": true,
      "node": "plant.top",
      "value": "p",
      "time": {"from": "18:50", "to": "19:05", "days": {"mon", "wed", "fri"}},
      "on":  {"op": "<=", "setpoint": 95.0, "cmd": "-n relay -r water -s on"}
    },{
      "enabled": true,
      "node": "plant.top",
      "value": "p",
      "time": {"from": "20:30", "to": "20:45", "days": {"sat"}},
      "on":  {"op": "<=", "setpoint": 95.0, "cmd": "-n relay -r water -s on"}
    }, "default": {"cmd": "-n relay -r water -s off"}],
    "lvl": [{
      "enabled": true,
      "node": "sump",
      "value": "cm",
      "on":  {"op": "<=", "setpoint": 23.1, "cmd": "-n relay -r drain -s on"},
      "off": {"op": ">=", "setpoint": 26.5, "cmd": "-n relay -r drain -s off"},
      "alert": {"op": "<=", "setpoint": 21.0, "title": "High water level alert"}
    },
    {
      "enabled": true,
      "node": "tank",
      "value": "cm",
      "on":  {"op": ">", "setpoint": 27.0, "cmd": "-n valve -v filter -s on"},
      "off": {"op": "<=", "setpoint": 27.0, "cmd": "-n valve -v filter -s off"},
      "alert": {"op": "<=", "setpoint": 24.0, "title": "High water level alert"}
    }],
    "clm": [{
      "enabled": true,
      "node": "climate",
      "value": "tmp",
      "on":  {"op": ">",  "setpoint": 23.5, "cmd": "-n relay -r vent -s on"},
      "off": {"cmd": "-n relay -r vent -s off"},
      "alert": {"op": ">=", "setpoint": 26.0, "title": "High temperature alert"}
    },
    {
      "enabled": true,
      "node": "climate",
      "value": "rh",
      "on":  {"op": ">",  "setpoint": 55.0, "cmd": "-n relay -r dh -s on"},
      "off": {"cmd": "-n relay -r dh -s off"},
      "alert": {"op": ">=", "setpoint": 65.0, "title": "High humidity alert"}
    }],
    "rly": [{
      "enabled": true,
      "node": "relay",
      "value": "r",
      "state": "s"
    }],
    "vlv": [{
      "enabled": true,
      "node": "valve",
      "value": "v",
      "state": "s"
    }],
    "timers": [{
      "enabled": true,
      "task": "light",
      "value": "ts",
      "time": {"from": "18:00", "to": "12:00"},
      "on":  {"cmd": "-n relay -r light -s on"},
      "off": {"cmd": "-n relay -r light -s off"}
    },
    {
      "enabled": true,
      "task": "air",
      "value": "ts",
      "time": {"from": "00:00", "to": "23:59"},
      "on":  {"cmd": "-n relay -r air -s on"},
      "off": {"cmd": "-n relay -r air -s off"}
    }]
  },
  "report": {
    "noData": "No data available"
  }
}
