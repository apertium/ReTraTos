#!/bin/sh

aclocal -I m4 || exit 1
autoconf || exit 1
automake -a || exit 1
