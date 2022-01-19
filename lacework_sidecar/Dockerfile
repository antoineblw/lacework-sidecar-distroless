FROM lacework/datacollector:latest-sidecar


RUN mkdir /shared
RUN mkdir /shared/bin
ADD busybox /shared/bin/busybox
#ADD https://github.com/mosajjal/binary-tools/raw/master/x64/busybox /shared/bin/busybox
#RUN chmod +x /shared/bin/busybox

RUN ln -s /shared/bin/busybox /shared/bin/cat
RUN ln -s /shared/bin/busybox /shared/bin/chown
RUN ln -s /shared/bin/busybox /shared/bin/chmod
RUN ln -s /shared/bin/busybox /shared/bin/cut
RUN ln -s /shared/bin/busybox /shared/bin/echo
RUN ln -s /shared/bin/busybox /shared/bin/grep
RUN ln -s /shared/bin/busybox /shared/bin/gunzip
RUN ln -s /shared/bin/busybox /shared/bin/ls
RUN ln -s /shared/bin/busybox /shared/bin/ln
RUN ln -s /shared/bin/busybox /shared/bin/mkdir
RUN ln -s /shared/bin/busybox /shared/bin/mktemp
RUN ln -s /shared/bin/busybox /shared/bin/rm
RUN ln -s /shared/bin/busybox /shared/bin/sed
RUN ln -s /shared/bin/busybox /shared/bin/sh
RUN ln -s /shared/bin/busybox /shared/bin/sha1sum
RUN ln -s /shared/bin/busybox /shared/bin/touch
RUN ln -s /shared/bin/busybox /shared/bin/tr
RUN ln -s /shared/bin/busybox /shared/bin/uname
RUN ln -s /shared/bin/busybox /shared/bin/whoami

ADD lacework-sidecar.sh /shared/bin

VOLUME /shared

