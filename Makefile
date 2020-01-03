PONYC ?= ponyc
config ?= debug
ifdef config
  ifeq (,$(filter $(config),debug release))
    $(error Unknown configuration "$(config)")
  endif
endif

ifeq ($(config),debug)
	PONYC_FLAGS += --debug
endif

PONYC_FLAGS += -o build/$(config)

ifeq ($(ssl),1.1.x)
  PONYC_FLAGS += -Dopenssl_1.1.x
else ifeq ($(ssl),0.9.0)
  PONYC_FLAGS += -Dopenssl_0.9.0
else
  PONYC_FLAGS += -Dopenssl_1.1.x
endif

ALL: test

build/$(config)/test: PONYC_FLAGS += --bin-name=test
build/$(config)/test: .deps build jennet/*.pony jennet/radix/*.pony
	stable env ${PONYC} ${PONYC_FLAGS} jennet

build/$(config):
	mkdir -p build/$(config)

build:
	mkdir -p build/$(config)

.deps:
	stable fetch

test: build/$(config)/test
	build/$(config)/test

examples: build/$(config) .deps build jennet/*.pony jennet/radix/*.pony examples/*/*.pony
	stable env ${PONYC} ${PONYC_FLAGS} examples/basicauth
	stable env ${PONYC} ${PONYC_FLAGS} examples/params
	stable env ${PONYC} ${PONYC_FLAGS} examples/servedir
	stable env ${PONYC} ${PONYC_FLAGS} examples/servefile

clean:
	rm -rf build

.PHONY: clean test
