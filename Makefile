.PHONY: all
all:
	@echo Nothing to do

build:
	# build zeromq
	git clone --depth=1 https://github.com/zeromq/libzmq.git
	mkdir -p zeromq/build; \
	cd zeromq/build; \
	cmake ..; \
	make; \
	sudo make install