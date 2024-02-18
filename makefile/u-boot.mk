#
# Makefile wrapper for U-Boot.
#
# Copyright (c) 2024 Man Hung-Coeng <udc577@126.com>
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

ARCH ?= arm
CROSS_COMPILE ?= arm-linux-gnueabihf-
MAKE_ARGS := ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} $(if ${__VER__},EXTRAVERSION=-${__VER__})
CP ?= cp -R -P
DIFF ?= diff --color
TOUCH ?= touch
UNCOMPRESS ?= tar -zxvf
PKG_FILE ?= ./uboot-imx-rel_imx_4.1.15_2.1.0_ga.tar.gz
PKG_URL ?= https://github.com/nxp-imx/uboot-imx/archive/refs/tags/rel_imx_4.1.15_2.1.0_ga.tar.gz
PKG_DOWNLOAD ?= wget -c '$(strip ${PKG_URL})' -O ${PKG_FILE}
SRC_PARENT_DIR ?= ./_tmp_
SRC_ROOT_DIR ?= $(shell \
    [ -f ${PKG_FILE} -o -d ${SRC_PARENT_DIR}/$(notdir ${PKG_FILE:.tar.gz=}) ] || ${PKG_DOWNLOAD} >&2; \
    [ -d ${SRC_PARENT_DIR}/$(notdir ${PKG_FILE:.tar.gz=}) ] || (mkdir -p ${SRC_PARENT_DIR}; ${UNCOMPRESS} ${PKG_FILE} -C ${SRC_PARENT_DIR}) >&2; \
    ls -d ${SRC_PARENT_DIR}/$(notdir ${PKG_FILE:.tar.gz=}) \
)
INSTALL_DIR ?= ${HOME}/tftpd
INSTALL_CMD ?= [ -d ${INSTALL_DIR} ] || mkdir -p ${INSTALL_DIR}; ${CP} ${SRC_ROOT_DIR}/u-boot* ${INSTALL_DIR}/
UNINSTALL_CMD ?= ls ${INSTALL_DIR}/u-boot* | grep -v u-boot.mk | xargs -I {} rm {}
DEFCONFIG ?= configs/mx6ull_14x14_evk_nand_defconfig
EXTRA_TARGETS ?= dtbs
CUSTOM_FILES ?= ${DEFCONFIG} \
    include/configs/mx6ullevk.h \
    board/freescale/mx6ullevk/mx6ullevk.c \
    drivers/net/phy/ti.c
__CUSTOMIZED_DEPENDENCIES := $(foreach i, ${CUSTOM_FILES}, ${SRC_ROOT_DIR}/${i})

$(foreach i, DEFCONFIG EXTRA_TARGETS, $(eval ${i} := $(strip ${${i}})))

.PHONY: all menuconfig $(if ${DEFCONFIG},defconfig) download clean distclean install uninstall ${EXTRA_TARGETS}

all: ${__CUSTOMIZED_DEPENDENCIES}
	${MAKE} -C ${SRC_ROOT_DIR} ${MAKE_ARGS} -j $$(grep -c processor /proc/cpuinfo)

menuconfig: $(if ${DEFCONFIG},defconfig) ${__CUSTOMIZED_DEPENDENCIES}
	[ -z "${DEFCONFIG}" ] && conf_file=.config || conf_file=${DEFCONFIG}; \
	[ "$${conf_file}" == ".config" -a -f $${conf_file} ] && ${CP} $${conf_file} ${SRC_ROOT_DIR}/.config || : ; \
	${MAKE} menuconfig -C ${SRC_ROOT_DIR} ${MAKE_ARGS} EXTRAVERSION=""; \
	if [ -f ${SRC_ROOT_DIR}/.config ]; then \
		set -x; \
		[ -f $${conf_file} ] && ${DIFF} ${SRC_ROOT_DIR}/.config $${conf_file} || ${CP} ${SRC_ROOT_DIR}/.config $${conf_file}; \
	fi

ifneq (${DEFCONFIG},)

defconfig: ${SRC_ROOT_DIR}/${DEFCONFIG}
	${MAKE} $(notdir ${DEFCONFIG}) -C ${SRC_ROOT_DIR} ${MAKE_ARGS} EXTRAVERSION=""

endif

download:
	[ -f ${PKG_FILE} ] || ${PKG_DOWNLOAD}

install:
	${INSTALL_CMD}

uninstall:
	${UNINSTALL_CMD}

${EXTRA_TARGETS}: ${__CUSTOMIZED_DEPENDENCIES}

clean distclean ${EXTRA_TARGETS}: %:
	${MAKE} $@ -C ${SRC_ROOT_DIR} ${MAKE_ARGS}

ifeq (1,1)

define custom_file_rule
${SRC_ROOT_DIR}/${1}: ${1}
	${DIFF} ${SRC_ROOT_DIR}/${1} ${1} && ${TOUCH} ${SRC_ROOT_DIR}/${1} || ${CP} ${1} ${SRC_ROOT_DIR}/${1}
endef

$(foreach i, ${CUSTOM_FILES}, $(eval $(call custom_file_rule,${i})))

else # This works as well, but it's more complecated for writing.

NULL :=
\t := ${NULL}	${NULL}
define \n


endef

$(foreach i, ${CUSTOM_FILES}, \
    $(eval \
        ${SRC_ROOT_DIR}/${i}: ${i} \
            ${\n}${\t}${DIFF} ${SRC_ROOT_DIR}/${i} ${i} && ${TOUCH} ${SRC_ROOT_DIR}/${i} || ${CP} ${i} ${SRC_ROOT_DIR}/${i} \
    ) \
)

endif

# Failure case (1): target 'xxx' doesn't match the target pattern
#${CUSTOM_FILES}: ${SRC_ROOT_DIR}/%: %
# Failure case (2): substitution failure which leads to circular dependency
#${__CUSTOMIZED_DEPENDENCIES}: %: $(subst ${SRC_ROOT_DIR}/,,%)
#	${DIFF} $@ $< && ${TOUCH} $@ || ${CP} $< $@ # Shared by (1) and (2)

# Failure case (3): never triggered
#${__CUSTOMIZED_DEPENDENCIES}: %:
# Failure case (4): almost a success except for the thundering herd problem
#${__CUSTOMIZED_DEPENDENCIES}: %: ${CUSTOM_FILES}
#	${DIFF} $@ ${@:${SRC_ROOT_DIR}/%=%} && ${TOUCH} $@ || ${CP} ${@:${SRC_ROOT_DIR}/%=%} $@ # Shared by (3) and (4)

help:
	@echo "Core directives:"
	@echo "  1. make download   - Download the source package manually; Usually unnecessary"
	@echo "  2. make menuconfig - Interactive configuration (automatically saved if changed)"
	@echo "  3. make            - Build U-Boot in a default way"
	@echo "  4. make clean      - Clean most generated files and directories"
	@echo "  5. make distclean  - Clean all generated files and directories (including .config)"
	@echo "  6. make install    - Copy the generated u-boot* files to the directory specified by INSTALL_DIR"
	@echo "  7. make uninstall  - Delete u-boot* files in the directory specified by INSTALL_DIR"
	@echo ""
	@printf "Extra directive(s): "
ifeq (${EXTRA_TARGETS},)
	@echo "None"
else
	@for i in ${EXTRA_TARGETS}; \
	do \
		printf "\n  * make $${i}"; \
	done
	@printf "\n  --"
	@printf "\n  Run \"make help\" in directory[${SRC_ROOT_DIR}]"
	@printf "\n  to see detailed descriptions."
	@printf "\n"
endif

#
# ================
#   CHANGE LOG
# ================
#
# >>> 2024-01-18, Man Hung-Coeng <udc577@126.com>:
#   01. Create.
#
# >>> 2024-01-19, Man Hung-Coeng <udc577@126.com>:
#   01. Fix the bug of infinite recursion (due to the invocation of
#       "make download" within the SRC_ROOT_DIR definition block) in absence of
#       ${SRC_PKG_FILE} and ${SRC_PARENT_DIR}/u*boot-*.
#   02. Strip heading and trailing blanks of several variables
#       for the sake of robustness and conciseness.
#   03. Deduce the resulting file of "make menuconfig" intelligently.
#   04. Support multiple source directories with different versions.
#
# >>> 2024-02-02, Man Hung-Coeng <udc577@126.com>:
#   01. Add "install" and "uninstall" targets.
#
# >>> 2024-02-04, Man Hung-Coeng <udc577@126.com>:
#   01. Remove --preserve and --update options of CP definition
#       to avoid old timestamps and unexpected skipping.
#   02. Update the help info.
#   03. Change the default value of INSTALL_DIR from ${PWD} to ${HOME}/tftpd.
#
# >>> 2024-02-14, Man Hung-Coeng <udc577@126.com>:
#   01. Change the non-error output redirection of Shell commands of
#       SRC_ROOT_DIR definition from /dev/null to stderr.
#   02. Beautify the display of extra directive(s) of "make help".
#   03. Rename variable SRC_PKG_* to PKG_*.
#   04. Make EXTRA_TARGETS depend on CUSTOM_FILES.
#
# >>> 2024-02-18, Man Hung-Coeng <udc577@126.com>:
#   01. Make target "menuconfig" depend on CUSTOM_FILES.
#

