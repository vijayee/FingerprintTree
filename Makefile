build:
	mkdir -p build
test: build
	mkdir -p build/test
test/FingerprintTree: test FingerprintTree/test/*.pony
	stable fetch
	stable env ponyc FingerprintTree/test -o build/test --debug
test/execute: test/FingerprintTree
	./build/test/test
clean:
	rm -rf build

.PHONY: clean test
