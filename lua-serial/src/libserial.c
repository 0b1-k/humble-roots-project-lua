/*
    Copyright (c) 2010 god6or@gmail.com

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

#include "libserial.h"
#include "lauxlib.h"

#if defined(__linux__)
    #include <unistd.h>
    #include <fcntl.h>
    #include <termios.h>
    #include <errno.h>
    #include <sys/ioctl.h>
	#include <unistd.h>
    
    #define ASYNC_SPD_MASK 0x1030
    #define ASYNC_SPD_CUST 0x0030

    typedef struct {
        int f; // file descriptor
    } _serial_struct;

    // baud constants equivalents
    int bauds[][2] = {{B0,0},{B50,50},{B75,75},{B110,110},{B134,134},{B150,150},{B200,200},
        {B300,300},{B600,600},{B1200,1200},{B1800,1800},{B2400,2400},{B4800,4800},{B9600,9600},
        {B19200,19200},{B38400,38400},{B57600,57600},{B115200,115200},{B230400,230400},
        {B460800,460800},{B500000,500000},{B576000,576000},{B921600,921600},{B1000000,1000000},
        {B1152000,1152000},{B1500000,1500000},{B2000000,2000000},{B2500000,2500000},
        {B3000000,3000000},{B3500000,3500000},{B4000000,4000000},};
#elif defined(__WIN32__)
    #include <windows.h>

    typedef struct {
        HANDLE f; // file handle
    } _serial_struct;
#endif


// Frees reStruct structure (GC callback).
static int _str_serial_struct_free(lua_State *L) {
    if (lua_isuserdata(L, 1)) {
        //printf("\nFree called !!!!!!!!!!!!!!!!\n");
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        if (ss->f != -1) {
            close(ss->f);
            ss->f = -1;
        }
#elif defined(__WIN32__)
        if (ss->f != NULL) {
            CloseHandle(ss->f);
            ss->f = NULL;
        }
#endif
    }
    return 0;
}


// open port. Input parameter - port name. Returns port data struct as user data object.
static int _serial_open(lua_State *L) {
    if (lua_isstring(L, 1)) { // 1st parameter is string
#if defined(__linux__)
        int fd = open( lua_tostring(L, 1), O_RDWR|O_NOCTTY|O_NDELAY|O_NONBLOCK );
        if (fd != -1) { // file opened ok
            fcntl(fd, F_SETFL, O_NDELAY); // disable read blocking
            // create serial port structure
            _serial_struct *ss = lua_newuserdata(L, sizeof(_serial_struct));
            ss->f = fd;
            //printf("\nNew called !!!!!!!!!!!!!!!!\n");
            lua_newtable(L); // add __gc metamethod
            lua_pushcfunction(L, _str_serial_struct_free);
            lua_setfield(L, -2, "__gc");
            lua_setmetatable(L, -2);
            
            struct termios options; // configure port
            if (tcgetattr(ss->f, &options) >= 0) { // get terminal attributes
                options.c_cflag |= CLOCAL | CREAD; // enable receiver
                #if defined(CNEW_RTSCTS)
                    options.c_cflag &= ~(CNEW_RTSCTS);
                #endif
                options.c_lflag &= ~(ICANON|ECHO|ECHOE|ECHOK|ECHONL|ISIG|IEXTEN);
                options.c_oflag &= ~(OPOST);
                options.c_iflag &= ~(INLCR|IGNCR|ICRNL|IGNBRK|IXON|IXOFF|IXANY);
                tcsetattr(ss->f, TCSANOW, &options);
            }
        } else lua_pushnil(L);
#elif defined(__WIN32__)
        HANDLE ph = CreateFile( lua_tostring(L, 1), GENERIC_READ|GENERIC_WRITE,
            0, NULL, OPEN_EXISTING, 0, NULL);
        if (ph != INVALID_HANDLE_VALUE) {
            // create serial port structure
            _serial_struct *ss = lua_newuserdata(L, sizeof(_serial_struct));
            ss->f = ph;
            lua_newtable(L); // add __gc metamethod
            lua_pushcfunction(L, _str_serial_struct_free);
            lua_setfield(L, -2, "__gc");
            lua_setmetatable(L, -2);
            
            DCB dcb; // configure port
            if (GetCommState(ss->f, &dcb)) { // init port
                dcb.fBinary = TRUE;
                dcb.fOutxCtsFlow = FALSE;
                dcb.fOutxDsrFlow = FALSE;
                dcb.fDtrControl = DTR_CONTROL_DISABLE;
                dcb.fDsrSensitivity = FALSE;
                dcb.fTXContinueOnXoff = FALSE;
                dcb.fOutX = FALSE;
                dcb.fInX = FALSE;
                dcb.fErrorChar = FALSE;
                dcb.fNull = FALSE;
                dcb.fRtsControl = RTS_CONTROL_DISABLE;
                dcb.fAbortOnError = FALSE;
                SetCommState(ss->f, &dcb);
            }
        } else lua_pushnil(L);
#endif
    } else lua_pushnil(L);
    return 1;
}

// close port. Input parameter - port struct in userdata
static int _serial_close(lua_State *L) {
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        if (ss->f != -1) {
            close(ss->f);
            ss->f = -1;
        }
#elif defined(__WIN32__)
        if (ss->f != NULL) {
            CloseHandle(ss->f);
            ss->f = NULL;
        }
#endif
    }
    return 0;
}




// get baud rate
static int _serial_getBaud(lua_State *L) {
    int baud = -1;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        struct termios options;
        if (tcgetattr(ss->f, &options) >= 0) { // get terminal attributes
            baud = cfgetispeed(&options);
            // search corresponding baud rate
            for (int i=0; i<(sizeof(bauds) / sizeof(int))/2; i++) {
                if (baud == bauds[i][0]) {
                    baud = bauds[i][1];
                    break;
                }
            }
        }
#elif defined(__WIN32__)
        DCB dcb;
        if (GetCommState(ss->f, &dcb)) {
            baud = dcb.BaudRate;
        }
#endif
    }
    lua_pushinteger(L, baud);
    return 1;
}

// set port baud rate
static int _serial_setBaud(lua_State *L) {
    if ((lua_isuserdata(L, 1))&&(lua_isnumber(L,2))) { // 1st parameter is user data, 2nd is number
        _serial_struct *ss = lua_touserdata(L, 1);
        int baud = lua_tointeger(L, 2);
#if defined(__linux__)
        struct termios options;
        if (tcgetattr(ss->f, &options) >= 0) { // get terminal attributes
            int b = -1;
            // search corresponding baud constant
            for (int i=0; i<(sizeof(bauds) / sizeof(int))/2; i++) {
                if (baud == bauds[i][1]) {
                    b = bauds[i][0];
                    break;
                }
            }
            if (b != -1) { // set standard baud rate
                cfsetispeed(&options, b);
                cfsetospeed(&options, b);
                options.c_cflag |= (CLOCAL | CREAD);
                tcsetattr(ss->f, TCSADRAIN, &options); // set new attributes
            } else { // set non-standard baud rate
                uint16_t buf[32];
                ioctl(ss->f, TIOCGSERIAL, &buf);
                buf[6] = buf[7] / baud;
                buf[4] &= ~ASYNC_SPD_MASK;
                buf[4] |= ASYNC_SPD_CUST;
                ioctl(ss->f, TIOCSSERIAL, &buf);
            }
        }
#elif defined(__WIN32__)
        DCB dcb;
        if (GetCommState(ss->f, &dcb)) {
            dcb.BaudRate = baud;
            SetCommState(ss->f, &dcb);
        }
#endif
    }
    return 0;
}




// get number of data bits
static int _serial_getBits(lua_State *L) {
    int bits = -1;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        struct termios options;
        if (tcgetattr(ss->f, &options) >= 0) { // get terminal attributes
            options.c_cflag &= CSIZE;
            if (options.c_cflag == CS8) bits = 8;
            else if (options.c_cflag == CS7) bits = 7;
            else if (options.c_cflag == CS6) bits = 6;
            else if (options.c_cflag == CS5) bits = 5;
        }
#elif defined(__WIN32__)
        DCB dcb;
        if (GetCommState(ss->f, &dcb)) {
            bits = dcb.ByteSize;
        }
#endif
    }
    lua_pushinteger(L, bits);
    return 1;
}

// set port data bits
static int _serial_setBits(lua_State *L) {
    if ((lua_isuserdata(L, 1))&&(lua_isnumber(L,2))) { // 1st parameter is user data, 2nd is number
        _serial_struct *ss = lua_touserdata(L, 1);
        int bits = lua_tointeger(L, 2);
        if ((bits >= 5)&&(bits <= 8)) {
#if defined(__linux__)
            struct termios options;
            if (tcgetattr(ss->f, &options) >= 0) { // get terminal attributes
                if (bits == 8) bits = CS8;
                else if (bits == 7) bits = CS7;
                else if (bits == 6) bits = CS6;
                else if (bits == 5) bits = CS5;
                else bits = -1;
                if (bits != -1) {
                    options.c_cflag &= ~CSIZE;
                    options.c_cflag |= bits;
                    tcsetattr(ss->f, TCSADRAIN, &options); // set new attributes
                }
            }
#elif defined(__WIN32__)
            DCB dcb;
            if (GetCommState(ss->f, &dcb)) {
                dcb.ByteSize = bits;
                SetCommState(ss->f, &dcb);
            }
#endif
        }
    }
    return 0;
}




// get port parity
static int _serial_getParity(lua_State *L) {
    char parStr[2] = {0,0};
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        struct termios options;
        if (tcgetattr(ss->f, &options) >= 0) { // get terminal attributes
            if (options.c_cflag & PARENB) {
                if (options.c_cflag & PARODD) parStr[0] = 'o';
                else parStr[0] = 'e';
            } else parStr[0] = 'n';
        }
#elif defined(__WIN32__)
        DCB dcb;
        if (GetCommState(ss->f, &dcb)) {
            if (dcb.Parity == 0) parStr[0] = 'n';
            else if (dcb.Parity == 1) parStr[0] = 'o';
            else if (dcb.Parity == 2) parStr[0] = 'e';
            else if (dcb.Parity == 3) parStr[0] = 'm';
            else if (dcb.Parity == 4) parStr[0] = 's';
        }
#endif
    }
    lua_pushstring(L, parStr);
    return 1;
}

// set port parity
static int _serial_setParity(lua_State *L) {
    if ((lua_isuserdata(L, 1))&&(lua_isstring(L,2))) { // 1st parameter is user data, 2nd is number
        _serial_struct *ss = lua_touserdata(L, 1);
        size_t plen;
        char *parity = (char *)lua_tolstring(L, 2, &plen);

        if ((plen == 1)&&( (*parity == 'n')||(*parity == 'e')||(*parity == 'o'))) {
#if defined(__linux__)
            struct termios options;
            if (tcgetattr(ss->f, &options) >= 0) { // get terminal attributes
                if (*parity == 'n') options.c_cflag &= ~PARENB;
                else {
                    options.c_cflag |= PARENB;
                    if (*parity == 'o') options.c_cflag |= PARODD;
                    else options.c_cflag &= ~PARODD;
                }
                tcsetattr(ss->f, TCSADRAIN, &options); // set new attributes
            }
#elif defined(__WIN32__)
            DCB dcb;
            if (GetCommState(ss->f, &dcb)) {
                if (*parity == 'n') dcb.Parity = 0;
                else if (*parity == 'o') dcb.Parity = 1;
                else if (*parity == 'e') dcb.Parity = 2;
                else if (*parity == 'm') dcb.Parity = 3;
                else if (*parity == 's') dcb.Parity = 4;
                SetCommState(ss->f, &dcb);
            }
#endif
        }
    }
    return 0;
}




// get port stop bits
static int _serial_getStops(lua_State *L) {
    int stops = -1;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        struct termios options;
        if (tcgetattr(ss->f, &options) >= 0) { // get terminal attributes
            if (options.c_cflag & CSTOPB) stops = 2;
            else stops = 0;
        }
#elif defined(__WIN32__)
        DCB dcb;
        if (GetCommState(ss->f, &dcb)) {
            stops = dcb.StopBits;
        }
#endif
    }
    lua_pushinteger(L, stops);
    return 1;
}

// set port stop bits (0-1, 1-1.5, 2-2)
static int _serial_setStops(lua_State *L) {
    if ((lua_isuserdata(L, 1))&&(lua_isnumber(L,2))) { // 1st parameter is user data, 2nd is number
        _serial_struct *ss = lua_touserdata(L, 1);
        int stops = lua_tointeger(L, 2);
        
        if ((stops >= 0)&&(stops <= 2)) {
#if defined(__linux__)
            struct termios options;
            if (tcgetattr(ss->f, &options) >= 0) { // get terminal attributes
                if (stops == 0) options.c_cflag &= ~CSTOPB;
                else options.c_cflag |= CSTOPB;
                tcsetattr(ss->f, TCSADRAIN, &options); // set new attributes
            }
#elif defined(__WIN32__)
            DCB dcb;
            if (GetCommState(ss->f, &dcb)) {
                dcb.StopBits = stops;
                SetCommState(ss->f, &dcb);
            }
#endif
        }
    }
    return 0;
}




// get state of RI line
static int _serial_getRI(lua_State *L) {
    int state = -1;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        int status;
        ioctl(ss->f, TIOCMGET, &status);
        if (status & TIOCM_RI) state = 1;
        else state = 0;
#elif defined(__WIN32__)
        DWORD status;
        if (GetCommModemStatus(ss->f, &status)) {
            if (status & MS_RING_ON) state = 1;
            else state = 0;
        }
#endif
    }
    lua_pushinteger(L, state);
    return 1;
}

// get state of CTS line
static int _serial_getCTS(lua_State *L) {
    int state = -1;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        int status;
        ioctl(ss->f, TIOCMGET, &status);
        if (status & TIOCM_CTS) state = 1;
        else state = 0;
#elif defined(__WIN32__)
        DWORD status;
        if (GetCommModemStatus(ss->f, &status)) {
            if (status & MS_CTS_ON) state = 1;
            else state = 0;
        }
#endif
    }
    lua_pushinteger(L, state);
    return 1;
}

// get state of DCD line
static int _serial_getDCD(lua_State *L) {
    int state = -1;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        int status;
        ioctl(ss->f, TIOCMGET, &status);
        if (status & TIOCM_CD) state = 1;
        else state = 0;
#elif defined(__WIN32__)
        DWORD status;
        if (GetCommModemStatus(ss->f, &status)) {
            if (status & MS_RLSD_ON) state = 1;
            else state = 0;
        }
#endif
    }
    lua_pushinteger(L, state);
    return 1;
}

// get state of DSR line
static int _serial_getDSR(lua_State *L) {
    int state = -1;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        int status;
        ioctl(ss->f, TIOCMGET, &status);
        if (status & TIOCM_DSR) state = 1;
        else state = 0;
#elif defined(__WIN32__)
        DWORD status;
        if (GetCommModemStatus(ss->f, &status)) {
            if (status & MS_DSR_ON) state = 1;
            else state = 0;
        }
#endif
    }
    lua_pushinteger(L, state);
    return 1;
}

// get state of DTR line
static int _serial_getDTR(lua_State *L) {
    int state = -1;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        int status;
        ioctl(ss->f, TIOCMGET, &status);
        if (status & TIOCM_DTR) state = 1;
        else state = 0;
#elif defined(__WIN32__)
#endif
    }
    lua_pushinteger(L, state);
    return 1;
}

// set DTR
static int _serial_setDTR(lua_State *L) {
    if ((lua_isuserdata(L, 1))&&(lua_isnumber(L,2))) { // 1st parameter is user data, 2nd is number
        _serial_struct *ss = lua_touserdata(L, 1);
        int state = lua_tointeger(L, 2);
        
        if ((state == 0)||(state == 1)) {
#if defined(__linux__)
            int status;
            ioctl(ss->f, TIOCMGET, &status);
            if (state) status |= TIOCM_DTR;
            else status &= ~TIOCM_DTR;
            ioctl(ss->f, TIOCMSET, &status);
#elif defined(__WIN32__)
            if (state) EscapeCommFunction(ss->f, SETDTR);
            else EscapeCommFunction(ss->f, CLRDTR);
#endif
        }
    }
    return 0;
}

// get state of RTS line
static int _serial_getRTS(lua_State *L) {
    int state = -1;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        int status;
        ioctl(ss->f, TIOCMGET, &status);
        if (status & TIOCM_RTS) state = 1;
        else state = 0;
#elif defined(__WIN32__)
#endif
    }
    lua_pushinteger(L, state);
    return 1;
}

// set RTS
static int _serial_setRTS(lua_State *L) {
    if ((lua_isuserdata(L, 1))&&(lua_isnumber(L,2))) { // 1st parameter is user data, 2nd is number
        _serial_struct *ss = lua_touserdata(L, 1);
        int state = lua_tointeger(L, 2);
        
        if ((state == 0)||(state == 1)) {
#if defined(__linux__)
            int status;
            ioctl(ss->f, TIOCMGET, &status);
            if (state) status |= TIOCM_RTS;
            else status &= ~TIOCM_RTS;
            ioctl(ss->f, TIOCMSET, &status);
#elif defined(__WIN32__)
            if (state) EscapeCommFunction(ss->f, SETRTS);
            else EscapeCommFunction(ss->f, CLRRTS);
#endif
        }
    }
    return 0;
}

// set Break
static int _serial_setBreak(lua_State *L) {
    if ((lua_isuserdata(L, 1))&&(lua_isnumber(L,2))) { // 1st parameter is user data, 2nd is number
        _serial_struct *ss = lua_touserdata(L, 1);
        int state = lua_tointeger(L, 2);
        
        if ((state == 0)||(state == 1)) {
#if defined(__linux__)
            if (state) ioctl(ss->f, TIOCCBRK);
            else ioctl(ss->f, TIOCSBRK);
#elif defined(__WIN32__)
            if (state) SetCommBreak(ss->f);
            else ClearCommBreak(ss->f);
#endif
        }
    }
    return 0;
}



// get number of received bytes in buffer
static int _serial_availRX(lua_State *L) {
    int nbytes = 0;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        ioctl(ss->f, TIOCINQ, &nbytes);
#elif defined(__WIN32__)
        COMSTAT stat;
        DWORD errors;
        if (ClearCommError(ss->f, &errors, &stat)) {
            nbytes = stat.cbInQue;
        }
#endif
    }
    lua_pushinteger(L, nbytes);
    return 1;
}

// read received bytes
static int _serial_read(lua_State *L) {
    int nbytes = 0;
    char *data = NULL;
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        ioctl(ss->f, FIONREAD, &nbytes); // get number of available bytes
        if (nbytes > 0) {
            data = malloc(nbytes);
            nbytes = read(ss->f, data, nbytes);
        }
#elif defined(__WIN32__)
        COMSTAT stat;
        DWORD errors;
        DWORD nbread;
        if (ClearCommError(ss->f, &errors, &stat)) {
            nbytes = stat.cbInQue;
            data = malloc(nbytes);
            ReadFile(ss->f, data, nbytes, &nbread, NULL);
            nbytes = nbread;
        }
#endif
    }
    lua_pushlstring(L, data, nbytes);
    if (data != NULL) free(data); // free allocated buffer
    return 1;
}

// write string to port
static int _serial_write(lua_State *L) {
    int dsent = 0; // number of bytes sent
    if ((lua_isuserdata(L, 1))&&(lua_isstring(L,2))) { // 1st parameter is user data, 2nd is string
        _serial_struct *ss = lua_touserdata(L, 1);
        size_t dlen;
        char *data = (char *)lua_tolstring(L, 2, &dlen);
        if (dlen > 0) {
#if defined(__linux__)
            dsent = write(ss->f, data, dlen);
#elif defined(__WIN32__)
            if (!WriteFile(ss->f, data, dlen, (PDWORD)&dsent, NULL)) dsent = 0;
#endif
        }
    }
    lua_pushinteger(L, dsent);
    return 1;
}


// flush input queue
static int _serial_flushRX(lua_State *L) {
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        tcflush(ss->f, TCIFLUSH);
#elif defined(__WIN32__)
        PurgeComm(ss->f, PURGE_RXCLEAR);
#endif
    }
    return 0;
}

// flush output queue
static int _serial_flushTX(lua_State *L) {
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        tcflush(ss->f, TCOFLUSH);
#elif defined(__WIN32__)
        PurgeComm(ss->f, PURGE_TXCLEAR);
#endif
    }
    return 0;
}

// wait to empty TX queue
static int _serial_drainTX(lua_State *L) {
    if (lua_isuserdata(L, 1)) { // 1st parameter is user data
        _serial_struct *ss = lua_touserdata(L, 1);
#if defined(__linux__)
        tcdrain(ss->f);
#elif defined(__WIN32__)
        DWORD   dwErrors;
        COMSTAT comStat;
        do {
            ClearCommError(ss->f, &dwErrors, &comStat);
        } while (comStat.cbOutQue > 0);
#endif
    }
    return 0;
}

// delay by n micro seconds
static int _serial_delay_us(lua_State *L) {
    if (lua_isnumber(L,1)) { // 1st parameter is number
    	int delay_us = lua_tointeger(L, 1);
    	usleep(delay_us);
    }
    return 0;
}

static const luaL_Reg exports[] = {
	{"open",       _serial_open},
	{"close",      _serial_close},
	{"getBaud",    _serial_getBaud},
	{"setBaud",    _serial_setBaud},
	{"getBits",    _serial_getBits},
	{"setBits",    _serial_setBits},
	{"getParity",  _serial_getParity},
	{"setParity",  _serial_setParity},
	{"getStops",   _serial_getStops},
	{"setStops",   _serial_setStops},
	{"getRI",      _serial_getRI},
	{"getCTS",     _serial_getCTS},
	{"getDCD",     _serial_getDCD},
	{"read",       _serial_read},
	{"write",      _serial_write},
	{"availRX",    _serial_availRX},
	{"flushRX",    _serial_flushRX},
	{"flushTX",    _serial_flushTX},
	{"drainTX",    _serial_drainTX},
	{"getDTR",     _serial_getDTR},
	{"setDTR",     _serial_setDTR},
	{"getRTS",     _serial_getRTS},
	{"setRTS",     _serial_setRTS},
	{"setBreak",   _serial_setBreak},
	{"getDSR",     _serial_getDSR},
	{"delay_us",   _serial_delay_us},
	{NULL, NULL}
};

LUA_API int luaopen_libserial(lua_State *L) {
	luaL_newlib(L, exports);
    return 1;
}

