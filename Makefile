PROTOC_C ?= protoc-c
PKG_CONFIG ?= pkg-config

# Note: Use "-C .git" to avoid ascending to parent dirs if .git not present
GIT_REVISION_ID = $(shell git -C .git rev-parse --short HEAD 2>/dev/null)
PLUGIN_VERSION ?= $(shell cat VERSION)~git$(GIT_REVISION_ID)
PKG_DEPS ?= purple glib-2.0 json-glib-1.0

CFLAGS	?= -O2 -g -pipe -Wall
LDFLAGS ?= -Wl,-z,relro

ifdef SUPPORT_EXTERNAL_ATTACHMENTS
LDFLAGS += -lmagic
PKG_DEPS += gio-unix-2.0
CFLAGS += -DSUPPORT_EXTERNAL_ATTACHMENTS
endif

CFLAGS  += -std=c99 -DSIGNALD_PLUGIN_VERSION='"$(PLUGIN_VERSION)"' -DMARKDOWN_PIDGIN

CC ?= gcc

ifeq ($(shell $(PKG_CONFIG) --exists purple 2>/dev/null && echo "true"),)
  TARGET = FAILNOPURPLE
  DEST =
else
  TARGET = libsignald.so
  DEST = $(DESTDIR)$(shell $(PKG_CONFIG) --variable=plugindir purple)/
  LOCALEDIR = $(DESTDIR)$(shell $(PKG_CONFIG) --variable=datadir purple)/locale
  PIXMAPDIR = $(DESTDIR)$(shell $(PKG_CONFIG) --variable=datadir pidgin)/pixmaps/pidgin/protocols
endif

CFLAGS += -DLOCALEDIR=\"$(LOCALEDIR)\"

PURPLE_COMPAT_FILES :=
PURPLE_C_FILES := comms.c contacts.c direct.c groups.c message.c link.c libsignald.c state.c $(C_FILES)

.PHONY:	all FAILNOPURPLE clean install

LOCALES = $(patsubst %.po, %.mo, $(wildcard po/*.po))

all: $(TARGET)

libsignald.so: $(PURPLE_C_FILES) $(PURPLE_COMPAT_FILES)
	$(CC) -fPIC $(CFLAGS) $(CPPFLAGS) -shared -o $@ $^ $(LDFLAGS) `$(PKG_CONFIG) $(PKG_DEPS) --libs --cflags` $(INCLUDES) -Ipurple2compat -g -ggdb

FAILNOPURPLE:
	echo "You need libpurple development headers installed to be able to compile this plugin"

clean:
	rm -f $(TARGET)

gdb:
	gdb --args pidgin -c ~/.fake_purple -n -m

install:
	install -Dm644 "$(TARGET)" "$(DEST)$(TARGET)" 
	install -Dm644 icons/11/signal.png "$(PIXMAPDIR)/11/signal.png" 
	install -Dm644 icons/16/signal.png "$(PIXMAPDIR)/16/signal.png"
	install -Dm644 icons/48/signal.png "$(PIXMAPDIR)/48/signal.png"
	
