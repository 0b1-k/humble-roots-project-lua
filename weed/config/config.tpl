[log]
  level = "info"

[replay]
   enabled = true
   record = false
   recordDuration = 3600

[serial]
  enabled = false
  port = "/dev/ttyUSB0"
  baudrate = 115200

[influxDB]
  enabled = false
  host = "localhost"
  port = 8086
  db = "sensors"
  events = "events"
  
  [influxDB.udp]
    enabled = false
    sensors = 8089
    events = 8090

[sms]
  enabled = false
  port = "/dev/ttyUSB"
  port_range_min = 1
  port_range_max = 1
  baudrate = 115200
  accept = "+15551234567"
  dest = "+15551234567"

[shell]
  enabled = true
  bind = "localhost"
  port = 42024

[node]
  "2" = "plant"
  "4" = "sump"
  "20" = "relay"
  "30" = "tank"
  "40" = "climate"
  "50" = "valve"
  "60" = "plant-top"
  "70" = "lux"
  plant = "2"
  sump = "4"
  relay = "20"
  tank = "30"
  climate = "40"
  valve = "50"
  plant-top = "60"
  lux = "70"

[r]
  "0" = "dh"
  "1" = "drain"
  "2" = "vent"
  "3" = "water"
  "4" = "light"
  "5" = "air"
  dh = "0"
  drain = "1"
  vent = "2"
  water = "3"
  light = "4"
  air = "5"

[v]
  "0" = "filter"
  "1" = "v1"
  "2" = "v2"
  "3" = "v3"
  "4" = "v4"
  "5" = "v5"
  "6" = "v6"
  "7" = "v7"
  filter = "0"
  v1 = "1"
  v2 = "2"
  v3 = "3"
  v4 = "4"
  v5 = "5"
  v6 = "6"
  v7 = "7"

[s]
  "0" = "off"
  "1" = "on"
  off = "0"
  on = "1"

[tx]
  nak = "0"
  ack = "1"
  "0" = "nak"
  "1" = "ack"

[fixup.s]
  off = "0"
  on = "1"

[alerts]
  raise = "RAISED"
  clear = "CLEARED"

[report]
  noData = "No data available"
    
[control.tick]
  freqSec = 15

[control.nodeTimeout]
  freqSec = 300
  title = "Heartbeat timeout"
  reboot = false
  rebootAfter = 600
  rebootMsg = "Fatal heartbeat failure. Rebooting!"
  rebootCmd = "sudo reboot"

[control.signal]
  enabled = true
  value = "rssi"
  alert = {op = "<", setpoint = -80.0, title = "Low signal strength alert"}

[control.relay.rly]
  [control.relay.rly.0]
  value = "r"
  state = "s"

[control.valve.vlv]
  [control.valve.vlv.0]
  value = "v"
  state = "s"

[control.plant-top.srh]
  cmd = "-n relay -r water -s off"
  [control.plant-top.srh.0]
    enabled = false
    value = "p"
    time = {from = "18:50", to = "19:20", days = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]}
    on = {op = "<=", setpoint = 110.0, cmd = "-n relay -r water -s on"}

[control.plant.srh]
  cmd = "-n relay -r water -s off"
  [control.plant.srh.0]
    enabled = false
    value = "p"
    time = {from = "18:50", to = "19:20", days = {"sun", "mon", "tue", "wed", "thu", "fri", "sat", "sun"}}
    on = {op = "<=", setpoint = 100.0, cmd = "-n relay -r water -s on"}

[control.sump.lvl]
  [control.sump.lvl.0]
    enabled = true
    value = "cm"
    on = {op = "<=", setpoint = 23.1, cmd = "-n relay -r drain -s on"}
    off = {op = ">=", setpoint = 26.5, cmd = "-n relay -r drain -s off"}
    alert = {op = "<=", setpoint = 21.0, title = "High water level alert"}

[control.tank.lvl]
  [control.tank.lvl.0]
    enabled = true
    value = "cm"
    on = {op = ">", setpoint = 37.0, cmd = "-n valve -v filter -s on"}
    off = {op = "<=", setpoint = 37.0, cmd = "-n valve -v filter -s off"}
    alert = {op = "<=", setpoint = 32.0, title = "High water level alert"}

[control.climate.clm]
  [control.climate.clm.0]
    enabled = false
    value = "tmp"
    time = {from = "18:00", to = "06:00"}
    on = {op = ">", setpoint = 25.0, cmd = "-n relay -r vent -s on"}
    off = {cmd = "-n relay -r vent -s off"}
    alert = {op = ">=", setpoint = 27.5, title = "High temperature alert"}
  [control.climate.clm.1]
    enabled = true
    value = "tmp"
    on = {op = ">", setpoint = 21.0, cmd = "-n relay -r vent -s on"}
    off = {cmd = "-n relay -r vent -s off"}
    alert = {op = ">=", setpoint = 22.0, title = "High temperature alert"}
  [control.climate.clm.2]
    enabled = true
    value = "rh"
    time = {from = "00:00", to = "23:59"}
    on = {op = ">=", setpoint = 55.0, cmd = "-n relay -r dh -s on"}
    off = {cmd = "-n relay -r dh -s off"}
    alert = {op = ">=", setpoint = 60.0, title = "High humidity alert"}

[control.lux]
  [control.lux.lux.0]
    enabled = true
    value = "lux"
    time = {from = "00:00", to = "23:59"}
    alert = {op = ">", setpoint = 5.0, title = "Lab entered alert"}

[control.timers.light]
  cmd = "-n relay -r light -s off"
  [control.timers.light.0]
    enabled = true
    value = "ts"
    time = {from = "00:00", to = "23:59"}
    on = {cmd = "-n relay -r light -s on"}

[control.timers.air]
  cmd = "-n relay -r air -s off"
  [control.timers.air.0]
    enabled = true
    value = "ts"
    on = {cmd = "-n relay -r air -s on"}
