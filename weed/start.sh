#!/bin/sh
cd /home/pi/LuaDist/share/weed
sudo usb_modeswitch -v 0x12d1 -p 0x1505 -J
sleep 5
../../bin/lua control.lua > /dev/null 2>&1 &
