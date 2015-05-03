init:
	git submodule update --init

test: init
	xctool -workspace ios/src/conflux.xcworkspace -scheme conflux -sdk iphonesimulator test
