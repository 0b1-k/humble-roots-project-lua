--[[ Copyright (c) 2010 god6or@gmail.com under MIT license.

Serial port communication module.

Examples:
    Get list of available ports:
        ports = io.Serial:getPorts()
    After calling getPorts() list of system ports stored to io.Serial.ports variable:
        ports = io.Serial.ports
    Open port and set parameters. Port can be port's name or number (starting at 1):
            p = io.Serial{port='/dev/ttyUSB0', baud=9600,bits=8,stops=0,parity='n'}
        or
            p = io.Serial:open{5}:baud(1200):bits(8):stops(2):parity('e'):DTR(0):RTS(1)
    Set parameters:
            p:config{baud=1200,bits=8,stops=2,parity='e',DTR=0,RTS=1}
        or
            p:baud(1200):bits(8):stops(2):parity('e'):DTR(0):RTS(1)
    Send data:
        p:write(string)
    Wait all data to send:
        p:drainTX() or p:waitTX()
    Get number of bytes in receive buffer:
        avail = p:availRX()
    Wait for reception of at least 64 bytes, with 100-millisecond timeout:
        tout = p:waitRX(64, 1000)
        if tout == 0 then print('Timeout...') end
    Get received data:
        data = p:read()
    Close:
        p:close()
]]

-- load binary module
io._serial = require("libserial")

-- serial port class
io.Serial = {
    ports = nil,     -- serial ports found in system
    pd = nil,       -- port data (file id/handle etc)
    name = '',      -- port name
    opened = false, -- true if port opened
    rxTout = 1000,  -- maximum RX timeout (in 100-microsecond units)

    -- cache external functions
    del_us = io._serial.delay_us, -- microseconds delay function

    -- get available serial ports
    getPorts = function(self)
        local ports = {}
        local pn,pa = {},0 -- ports names (? replaced with port number), starting port number 
        -- detect operating system
        if not os.getenv('ComSpec') then -- Posix
            pn = {'/dev/ttyS?', '/dev/ttyUSB?', '/dev/ttyBT?', '/dev/ttyACM?'}
        else -- Windows
            pn,pa = {'com?'}, 1
        end
        -- try to open all ports, add existing to results array
    	for _,pp in ipairs(pn) do
            for pn=pa,255+pa do
                local ps,_ = pp:gsub('?',tostring(pn))
                local p = io._serial.open(ps)
                if p then
                    table.insert(ports, ps)
                    io._serial.close(p)
                end
            end
        end
        self.ports = ports -- store ports list
        return ports
    end,

    -- open new port
    open = function(self, args)
        local port = nil

        if not args then args = {} end
        if args[1] then args.port = args[1] end
        if not args.port then args.port = 1 end
        if type(args.port) == 'number' or tonumber(args.port) then
            if not self.ports then self:getPorts() end
            args.port = self.ports[tonumber(args.port)]
        end
        
        local pd = io._serial.open(args.port) -- create port structure
        if pd then
            port = {}
            setmetatable(port, self)
            self.__index = self

            port.pd = pd
            port.name = args.port
            port.opened = true

            port:config(args)
        end
        
        return port
    end,

    -- close opened port
    close = function(self)
        if self.pd ~= nil and self.opened then
            io._serial.close(self.pd)
            self.pd = nil
            -- self.name = ""
            self.opened = false
            return not self.opened -- return true if port succesfully closed
        else return nil -- return nilk if port not opened
        end
    end,

    -- set port parameters through table
    config = function(self, params)
        if type(params) == 'table' then
            self:baud(params.baud)
            self:bits(params.bits)
            self:stops(params.stops)
            self:parity(params.parity)
            self:DTR(params.DTR)
            self:RTS(params.RTS)
            if params.rxTout then self.rxTout = params.rxTout end
        end
        return self
    end,

    -- get/set baud rate. If baud==nil, returns baudrate
    baud = function(self, baud)
        if not baud then return io._serial.getBaud(self.pd)
        else
            io._serial.setBaud(self.pd, baud)
            return self
        end
    end,

    -- get/set data bits (5..8). If bits==nil, returns port bits.
    bits = function(self, bits)
        if not bits then return io._serial.getBits(self.pd)
        else
            io._serial.setBits(self.pd, bits)
            return self
        end
    end,

    -- get/set parity ('n','e','o'). If parity==nil, returns current parity.
    parity = function(self, parity)
        if not parity then return io._serial.getParity(self.pd)
        else
            io._serial.setParity(self.pd, parity:sub(1,1):lower())
            return self
        end
    end,

    -- get/set number of stop bits (0-1, 1-1.5, 2-2). If stops==nil, returns current stops.
    stops = function(self, stops)
        if not stops then return io._serial.getStops(self.pd)
        else
            io._serial.setStops(self.pd, stops)
            return self
        end
    end,
    
    -- get RI state
    RI = function(self)
        return io._serial.getRI(self.pd)
    end,
    -- get CTS state
    CTS = function(self)
        return io._serial.getCTS(self.pd)
    end,
    -- get DCD state
    DCD = function(self)
        return io._serial.getDCD(self.pd)
    end,
    -- get DSR state
    DSR = function(self)
        return io._serial.getDSR(self.pd)
    end,
    -- get/set DTR (0/1/-1 to invert). If state==nil, returns current state.
    DTR = function(self, state)
        if not state then return io._serial.getDTR(self.pd)
        else
            if state == -1 then io._serial.setDTR(self.pd, 1 - io._serial.getDTR(self.pd))
            else io._serial.setDTR(self.pd, state) end
            return self
        end
    end,
    -- get/set RTS (0/1/-1 to invert). If state==nil, returns current state.
    RTS = function(self, state)
        if not state then return io._serial.getRTS(self.pd)
        else
            if state == -1 then io._serial.setRTS(self.pd, 1 - io._serial.getRTS(self.pd))
            else io._serial.setRTS(self.pd, state) end
            return self
        end
    end,

    -- set break
    setBreak = function(self, state)
        io._serial.setBreak(self.pd, state)
        return self
    end,

    -- get number of available received bytes
    availRX = function(self)
        return io._serial.availRX(self.pd)
    end,
    available = function(self)
        return io._serial.availRX(self.pd)
    end,
    
    -- flush RX buffer
    flushRX = function(self)
        io._serial.flushRX(self.pd)
        return self
    end,
    -- flush TX buffer
    flushTX = function(self)
        io._serial.flushTX(self.pd)
        return self
    end,
    -- flush RX and TX buffers
    flush = function(self)
        self:flushTX():flushRX()
    end,
    -- wait until reception of nb bytes, waiting tout time (milliseconds)
    --   returns remaining timeout counter, == 0 if timeout occured.
    waitRX = function(self, nb, tout)
        if not tout then tout = self.rxTout end -- use default timeout
        while (self:availRX() < nb) and (tout > 0) do
            self.del_us(1000)
            tout = tout - 1
        end
        return tout
    end,
    -- wait until TX buffer clears
    drainTX = function(self)
        io._serial.drainTX(self.pd)
    end,
    waitTX = function(self)
        self:drainTX()
    end,

    -- read received data
    read = function(self)
        return io._serial.read(self.pd)
    end,
    -- write string to port
    write = function(self, data)
        return io._serial.write(self.pd, data)
    end,
}
setmetatable(io.Serial, {
    __call = function(self, args)
        return io.Serial:open(args)
    end,
})

