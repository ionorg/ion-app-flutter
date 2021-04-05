BUILD_CMD  := docker run --rm -it -v `pwd`:/home/developer/src flutter-builder

all: 
	docker build . -t flutter-builder
	$(BUILD_CMD) pub get
	$(BUILD_CMD) build web