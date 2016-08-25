MAIN := libserial

DIR_SRC   := ./src
DIR_BUILD := ./build

ifndef $(CPU)
	CPU       := pentium3
endif

ifndef COMSPEC
	# posix
	DIR_SEP := :
	LIBEXT  := .so
	LBITS   := $(shell getconf LONG_BIT)
	LIBS    := liblua
ifeq ($(OSTYPE), darwin)
	# mac os
	LFLAGS := -bundle -undefined dynamic_lookup
	ifeq ($(LBITS),64)
		SYSTEM := mac64
	else
		SYSTEM := mac32
	endif
else
	# linux/bsd
	ifeq ($(LBITS),64)
		SYSTEM := lin64
	else
		SYSTEM := lin32
	endif
	CFLAGS_SHARED := -fPIC
	LFLAGS        := -shared
endif
else
	# windows
ifeq ($(PROCESSOR_ARCHITECTURE), AMD64)
ifndef CC_PREFIX
	CC_PREFIX    := amd64-mingw32msvc-
endif
	SYSTEM       := win64
else
ifndef CC_PREFIX
	CC_PREFIX    := i586-mingw32msvc-
endif
	SYSTEM       := win32
endif
	DIR_SEP      := ;
	LIBEXT       := .dll
	EXEEXT       := .exe
	LIBS         := -llua
	LFLAGS       := -shared
endif

INCLUDE_DIRS := $(INCLUDE_DIRS) -I../../include -I$(LUA_HOME)/src
LIB_DIRS     := $(LIB_DIRS) -L../lua/build/$(SYSTEM) -L$(LUA_HOME)/bin -L$(LIB_DIRS)/lib

DIR_BUILD_ARCH := ./build/$(SYSTEM)

CC := $(CC_PREFIX)gcc
AR := $(CC_PREFIX)ar
RM := rm -f

CFLAGS := $(CFLAGS) -std=gnu99 -Os -g $(INCLUDE_DIRS) -ffunction-sections -fdata-sections
LFLAGS := $(LFLAGS) $(LIB_DIRS)
WFLAGS := $(WFLAGS) -Wall

build: static shared

static:
	$(CC) -c $(CFLAGS) $(WFLAGS) -o $(DIR_BUILD_ARCH)/$(MAIN).o $(DIR_SRC)/$(MAIN).c
	$(AR) rv $(DIR_BUILD_ARCH)/lib$(MAIN).a $(DIR_BUILD_ARCH)/$(MAIN).o
	$(RM) $(DIR_BUILD_ARCH)/$(MAIN).o

shared:
	$(CC) -c $(CFLAGS_SHARED) $(CFLAGS) $(WFLAGS) -o $(DIR_BUILD_ARCH)/$(MAIN).o $(DIR_SRC)/$(MAIN).c
	$(CC) $(LFLAGS) $(WFLAGS) -o $(DIR_BUILD_ARCH)/$(MAIN)$(LIBEXT) $(DIR_BUILD_ARCH)/$(MAIN).o
	$(RM) $(DIR_BUILD_ARCH)/$(MAIN).o

clean:
	$(RM) $(DIR_BUILD_ARCH)/*.o $(DIR_BUILD_ARCH)/*.a $(DIR_BUILD_ARCH)/*.so $(DIR_BUILD_ARCH)/*.dll

