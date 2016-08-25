#!/bin/sh
cd /home/pi/LuaDist/share/weed
sudo usb_modeswitch -v 0x12d1 -p 0x14fe -J
sleep 1
sudo smsd &
sudo ../../bin/lua control.lua > /dev/null 2>&1 &

