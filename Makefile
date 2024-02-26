CFLAGS=-Wall -g -framework AppKit -isysroot `xcrun --show-sdk-path`
BUILD_DIR=./build

all: main

$(BUILD_DIR):
	mkdir -p $@

main: $(BUILD_DIR) main.mm
	clang $(CFLAGS) main.mm -o $(BUILD_DIR)/main
	ln -shf $(BUILD_DIR)/main ./main

clean:
	rm $(BUILD_DIR)/main
