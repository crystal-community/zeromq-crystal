.PHONY: all
all:
	@echo Nothing to do

build:
	# build zeromq
	git clone --depth=1 https://github.com/zeromq/libzmq.git
	mkdir -p libzmq/build; \
	cd libzmq/build; \
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTS=OFF -DWITH_PERF_TOOL=OFF -DCMAKE_BUILD_TYPE="Release" ..; \
	make -j8; \
	sudo make install