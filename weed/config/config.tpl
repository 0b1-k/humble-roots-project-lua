{
  "log": {"level": "trace"},
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
    "db": "sensors",
    "events": "events",
    "udp" : {enabled: false, "sensors": 8089, "events": 8090}
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
    "70": "lux",
    "plant": "2",
    "sump": "4",
    "relay": "20",
    "tank": "30",
    "climate": "40",
    "valve": "50",
    "plant.top": "60",
    "lux": "70"
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
  "report": {
    "noData": "No data available"
  },
  "control": {
    
    "tick": {
      "freqSec": 15
    },

    "nodeTimeout": {
      "freqSec": 240,
      "title": "Heartbeat timeout",
      "reboot": false,
      "rebootAfter": 600,
      "rebootMsg": "Fatal heartbeat failure. Rebooting!",
      "rebootCmd": "sudo reboot"
    },

    "signal": [{
      "enabled": true,
      "value": "rssi",
      "alert": {"op": "<", "setpoint": -60.0, "title": "Low signal strength alert"}
    }],

    "plant.top": {
      "srh": [{
          "value": "p",
          "rules": [{
              "enabled": true,
              "time": {"from": "18:50", "to": "19:20", "days": {"sun", "mon", "tue", "wed", "thu", "fri", "sat", "sun"}},
              "on":  {"op": "<=", "setpoint": 110.0, "cmd": "-n relay -r water -s on"}
              }, "default": {"cmd": "-n relay -r water -s off"}
            ]
          }]
    },

    "plant": {
      "srh": [{
          "value": "p",
          "rules": [{
              "enabled": false,
              "time": {"from": "18:50", "to": "19:20", "days": {"sun", "mon", "tue", "wed", "thu", "fri", "sat", "sun"}},
              "on":  {"op": "<=", "setpoint": 100.0, "cmd": "-n relay -r water -s on"}
              }, "default": {"cmd": "-n relay -r water -s off"}
            ]
          }]
    },

    "sump": {
      "lvl": [{
          "value": "cm",
          "rules": [{
            "enabled": true,
            "on":  {"op": "<=", "setpoint": 23.1, "cmd": "-n relay -r drain -s on"},
            "off": {"op": ">=", "setpoint": 26.5, "cmd": "-n relay -r drain -s off"},
            "alert": {"op": "<=", "setpoint": 21.0, "title": "High water level alert"}
            }
          ]
        }]
    },

    "tank": {
      "lvl": [{
          "value": "cm",
          "rules": [{
            "enabled": true,
            "on":  {"op": ">", "setpoint": 37.0, "cmd": "-n valve -v filter -s on"},
            "off": {"op": "<=", "setpoint": 37.0, "cmd": "-n valve -v filter -s off"},
            "alert": {"op": "<=", "setpoint": 32.0, "title": "High water level alert"}
            }
          ]
      }]
    },

    "climate": {
        "clm": [{
          "value": "tmp",
            "rules": [{
              "enabled": true,
              "time": {"from": "18:00", "to": "06:00"},
              "on":  {"op": ">", "setpoint": 25.0, "cmd": "-n relay -r vent -s on"},
              "alert": {"op": ">=", "setpoint": 27.5, "title": "High temperature alert"}
              },{
              "enabled": true,
              "time": {"from": "06:01", "to": "17:59"},
              "on":  {"op": ">", "setpoint": 22.0, "cmd": "-n relay -r vent -s on"},
              "alert": {"op": ">=", "setpoint": 25, "title": "High temperature alert"}
              }, "default": {"cmd": "-n relay -r vent -s off"}
          ]},{
          "value": "rh",
            "rules": [{
              "enabled": true,
              "on":  {"op": ">=", "setpoint": 48.0, "cmd": "-n relay -r dh -s on"},
              "alert": {"op": ">=", "setpoint": 52.0, "title": "High humidity alert"}
              }, "default": {"cmd": "-n relay -r dh -s off"}
            ]
        }]
    },

    "relay": {
        "rly": [{
          "value": "r",
          "state": "s",
          "rules": [{
            "enabled": true
          }]
        }]
    },

    "valve": {
        "vlv": [{
          "value": "v",
          "state": "s",
          "rules": [{
            "enabled": true
            }]
        }]
    },

    "lux": {
        "lux": [{
          "value": "lux",
          "rules": [{
            "enabled": true
            }]
        }]
    },

    "timers": {
      "light": [{
          "value": "ts",
          "rules": [{
            "enabled": true,
            "time": {"from": "18:00", "to": "06:00"},
            "on":  {"cmd": "-n relay -r light -s on"}
            }, "default": {"cmd": "-n relay -r light -s off"}
          ]
      }],
      "air": [{
          "value": "ts",
          "rules": [{
            "enabled": true,
            "time": {"from": "00:00", "to": "23:59"},
            "on":  {"cmd": "-n relay -r air -s on"}
            }, "default": {"cmd": "-n relay -r air -s off"}
          ]
      }]
    },
  }
}