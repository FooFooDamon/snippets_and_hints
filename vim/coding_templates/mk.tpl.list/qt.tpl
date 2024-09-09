#
# Copyright (c) ${YEAR} ${LCS_USER} <${LCS_EMAIL}>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

.PHONY: all prepare dependencies

ifeq ($(shell [ -s __ver__.mk -a -s QtMakefile ] && echo 1 || echo 0),0)

LAZY_CODING_URL ?= https://github.com/FooFooDamon/lazy_coding_skills

all prepare: dependencies
	@[ -s __ver__.mk ] || wget -c "${LAZY_CODING_URL}/raw/main/makefile/__ver__.mk"
	@[ -s QtMakefile ] || qmake -o QtMakefile
	@echo "~ ~ ~ Minimum preparation finished successfully ~ ~ ~"
	@echo "Re-run your command again to continue your work."

else

all: dependencies

include __ver__.mk
include QtMakefile

OS_MACRO ?= -D__linux__
DEFINES += -D__VER__=\"${__VER__}\"
CFLAGS += -Wno-unused-parameter
CXXFLAGS += -Wno-unused-parameter
INCPATH +=
LFLAGS +=
LIBS +=
NO_CPPCHECK = true

.PHONY: ext_clean check ui_fix

clean: ext_clean

ext_clean:
	rm -f ${TARGET} *.d *.plist

check:
	-${NO_CPPCHECK} && printf "\n[Warning] Cppcheck has been disabled since it consumes too much time!\n%s\n\n" \
		"If you want to enable it, run with NO_CPPCHECK=false" \
		|| cppcheck --quiet --force --enable=all -j $$(nproc) --language=c++ --std=c++11 \
		--library=qt ${OS_MACRO} $$(g++ -dM -E - < /dev/null | grep ENDIAN | awk '{ printf("-D%s=%s\n", $$2, $$3) }') \
		${DEFINES} ${INCPATH} $(filter-out moc_%.cpp, ${SOURCES})
	clang --analyze $(filter-out moc_${TARGET}.cpp, ${SOURCES}) ${CXXFLAGS} ${INCPATH}

ui_fix: ui_${TARGET}.h
	sed -i 's/\(.*\<QPalette::PlaceholderText\>.*\)/\/\/\1/' $<

endif

export DEPENDENCY_DIRS ?= $(abspath ../3rdparty)

dependencies:
	@for i in ${DEPENDENCY_DIRS}; \
	do \
		[ -s $${i}/[Mm]akefile ] && ${MAKE} $(filter all prepare, ${MAKECMDGOALS}) -C $${i} || true; \
	done
