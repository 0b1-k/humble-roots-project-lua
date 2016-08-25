{
  "log": {
    "level": "trace"
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
    "accept": "15551112222",
    "dest": "15551112222",
    "outgoing": "/var/spool/sms/outgoing",
    "incoming": "/var/spool/sms/incoming"
  },
  "shell": {
    "enabled": false,
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
    "plant": "2",
    "sump": "4",
    "relay": "20",
    "tank": "30",
    "climate": "40",
    "valve": "50"
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
      "enabled": false,
      "node": "plant",
      "value": "p",
      "time": {"from": "18:50", "to": "19:00"},
      "on":  {"op": "<=", "setpoint": 95.0, "cmd": "node=relay&cmd=act&r=water&s=on"},
      "off": {"cmd": "node=relay&cmd=act&r=water&s=off"}
    }],
    "lvl": [{
      "enabled": false,
      "node": "sump",
      "value": "cm",
      "on":  {"op": "<=", "setpoint": 23.1, "cmd": "node=relay&cmd=act&r=drain&s=on"},
      "off": {"op": ">=", "setpoint": 26.5, "cmd": "node=relay&cmd=act&r=drain&s=off"},
      "alert": {"op": "<=", "setpoint": 21.0, "title": "High water level alert"}
    },
    {
      "enabled": false,
      "node": "tank",
      "value": "cm",
      "on":  {"op": ">", "setpoint": 27.0, "cmd": "node=valve&cmd=act&v=filter&s=on"},
      "off": {"op": "<=", "setpoint": 27.0, "cmd": "node=valve&cmd=act&v=filter&s=off"},
      "alert": {"op": "<=", "setpoint": 24.0, "title": "High water level alert"}
    }],
    "clm": [{
      "enabled": false,
      "node": "climate",
      "value": "tmp",
      "on":  {"op": ">",  "setpoint": 27.5, "cmd": "node=relay&cmd=act&r=vent&s=on"},
      "off": {"cmd": "node=relay&cmd=act&r=vent&s=off"},
      "alert": {"op": ">=", "setpoint": 28.0, "title": "High temperature alert"}
    },
    {
      "enabled": false,
      "node": "climate",
      "value": "rh",
      "on":  {"op": ">",  "setpoint": 55.0, "cmd": "node=relay&cmd=act&r=dh&s=on"},
      "off": {"cmd": "node=relay&cmd=act&r=dh&s=off"},
      "alert": {"op": ">=", "setpoint": 65.0, "title": "High humidity alert"}
    }],
    "rly": [{
      "enabled": false,
      "node": "relay",
      "value": "r",
      "state": "s"
    }],
    "vlv": [{
      "enabled": false,
      "node": "valve",
      "value": "v",
      "state": "s"
    }],
    "timers": [{
      "enabled": false,
      "task": "light",
      "value": "ts",
      "time": {"from": "00:00", "to": "23:59"},
      "on":  {"cmd": "node=relay&cmd=act&r=light&s=on"},
      "off": {"cmd": "node=relay&cmd=act&r=light&s=off"}
    },
    {
      "enabled": false,
      "task": "air",
      "value": "ts",
      "time": {"from": "00:00", "to": "23:59"},
      "on":  {"cmd": "node=relay&cmd=act&r=air&s=on"},
      "off": {"cmd": "node=relay&cmd=act&r=air&s=off"}
    }]
  },
  "report": {
    "noData": "No data available"
  }
}
