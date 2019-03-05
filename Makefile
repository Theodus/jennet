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

ALL: test

build/$(config)/test: PONYC_FLAGS += --bin-name=test
build/$(config)/test: .deps build jennet/*.pony
	stable env ${PONYC} ${PONYC_FLAGS} jennet

build/$(config)/examples:
	mkdir -p build/$(config)/examples

build:
	mkdir -p build/$(config)

.deps:
	stable fetch

test: build/$(config)/test
	build/$(config)/test

examples: build/$(config)/examples .deps build jennet/*.pony examples/*/*.pony
	stable env ${PONYC} ${PONYC_FLAGS} examples/basicauth
	stable env ${PONYC} ${PONYC_FLAGS} examples/params
	stable env ${PONYC} ${PONYC_FLAGS} examples/servedir
	stable env ${PONYC} ${PONYC_FLAGS} examples/servefile

clean:
	rm -rf build

.PHONY: clean test
