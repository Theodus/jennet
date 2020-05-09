config ?= debug
ifdef config
  ifeq (,$(filter $(config),debug release))
    $(error Unknown configuration "$(config)")
  endif
endif

ifeq ($(config),debug)
	PONYC_FLAGS += --debug
endif

PONYC := corral run -- ponyc
PONYC_FLAGS += -V1 -o build/$(config)

ifeq ($(ssl),1.1.x)
  PONYC_FLAGS += -Dopenssl_1.1.x
else ifeq ($(ssl),0.9.0)
  PONYC_FLAGS += -Dopenssl_0.9.0
else
  PONYC_FLAGS += -Dopenssl_1.1.x
endif

DEPS = _corral _repos
JENNET_SRCS = $(shell find jennet -name *.pony)
EXAMPLES = $(shell find examples/*/* -name '*.pony' -print | xargs -n 1 dirname)

ALL: test

build:
	mkdir -p build/$(config)

${DEPS}: corral.json
	corral fetch

build/$(config)/test: ${DEPS} build ${JENNET_SRCS}
	${PONYC} ${PONYC_FLAGS} --bin-name=test jennet

test: build/$(config)/test
	build/$(config)/test $(PONYTEST_ARGS)

examples: ${EXAMPLES}

${EXAMPLES}: ${DEPS} build ${JENNET_SRCS} $(shell find $@ -name *.pony)
	${PONYC} ${PONYC_FLAGS} $@

clean:
	rm -rf build
	corral clean

.PHONY: clean test examples
