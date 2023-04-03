ifeq ($(DRAWIO),)
	ifeq ($(OS),Windows_NT)
		DRAWIO := "C:/Program Files/Draw.io/drawio.exe"
	else
	    UNAME_S := $(shell uname -s)
		ifeq ($(UNAME_S),Linux)
			DRAWIO := /usr/bin/drawio
		endif
		ifeq ($(UNAME_S),Darwin)
			DRAWIO := /Applications/draw.io.app/Contents/MacOS/draw.io
		endif
	endif
endif

all: overview.png

overview.png: overview.drawio
	$(DRAWIO) -x --width 800 -t $^ -o $@
