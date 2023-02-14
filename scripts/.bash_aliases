#!/bin/bash

#
# Useful aliases.
#
# Copyright (c) 2023 Man Hung-Coeng <udc577@126.com>
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

if [ -n "${LAZY_CODING_HOME}" ]; then
    alias diff=colordiff
    alias dsk="cd ${HOME}/桌面 2> /dev/null || cd ${HOME}/Desktop"
    alias lc_reload=". ${LAZY_CODING_HOME}/scripts/__import__.sh"
    alias L="cd ${LAZY_CODING_HOME}"
    alias make="time make"
    alias pst="ps -eLo uid,pid,ppid,lwp,psr,c,stime,tname,time,args" # Means displaying [t]hread info while executing ps.
    alias rm=safer-rm.sh
    alias startx="printf '\\e[0;33mstartx should not be used when you have entered a graphic desktop\\e[0m\n'"
    alias tailf="tail --follow=name"
    alias tl="[ -e ${HOME}/logs ] || mkdir ${HOME}/logs; script -f ${HOME}/logs/terminal_log_\`date +%Y-%m-%d_%H_%M_%S\`.txt"
    alias valgrind="valgrind --tool=memcheck --leak-check=full --track-origins=yes --show-reachable=yes --log-file=valgrind_report.log"
fi

#
# ================
#   CHANGE LOG
# ================
#
# >>> V1.0.0|2023-02-12, Man Hung-Coeng <udc577@126.com>:
#   01. Create.
#
