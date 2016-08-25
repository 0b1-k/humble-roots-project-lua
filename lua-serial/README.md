ul_serial
=========

Lua serial port library

Donate: ** Paypal edartuz@gmail.com **

  
Serial port communication functions for Lua.
For timing functions requires function os.delay_us(us) (in ul_time module).
  
* Compilation with gcc (Linux) or MinGW-gcc (Windows):
  * `make`
* Cross-compilation in Linux:
  * 32-bit target: `make COMSPEC=command`
  * 64-bit target: `make COMSPEC=command PROCESSOR_ARCHITECTURE=AMD64 CPU=k8`
  
## Examples:
* Get list of available ports: `ports = io.Serial:getPorts()`
* After calling getPorts() list of system ports stored to io.Serial.ports variable: `ports = io.Serial.ports`
* Open port and set parameters. Port can be port's name or number (starting at 1):
  * `p = io.Serial{port='/dev/ttyUSB0', baud=9600,bits=8,stops=0,parity='n'}`
  * or `p = io.Serial:open{5}:baud(1200):bits(8):stops(2):parity('e'):DTR(0):RTS(1)`
* Set parameters:
  * `p:config{baud=1200,bits=8,stops=2,parity='e',DTR=0,RTS=1}`
  * or using method chaining: `p:baud(1200):bits(8):stops(2):parity('e'):DTR(0):RTS(1)`
* Get number of bytes waiting in receive buffer: `n = p:available()`
* Read all received data (as string): `p:read()`
* Wait for reception of at least 64 bytes, with 100ms timeout, receive data on success:
```lua
    to = p:waitRX(64, 100)
    if to == 0 then
    	print('Timeout occured...')
	else
		data = p:read()
	end
```
* Transmit string of bytes: `p:write(string)`
* Wait all data to send: `p:drainTX()` or `p:waitTX()`
* Close port: `p:close()`

