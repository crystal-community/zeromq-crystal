.PHONY: all
all:
	@echo Nothing to do

build:
	# build zeromq
	git clone --depth=1 https://github.com/zeromq/libzmq.git
	mkdir -p libzmq/build; \
	cd libzmq/build; \
	cmake -DCMAKE_INSTALL_PREFIX=/usr ..; \
	make -j8; \
	sudo make install