#!/bin/bash
. `dirname $0`/functions.sh
# First check if __thread is supported by ld.so/gcc/ld/as:
rm -f tlstest
echo '__thread int a; int main (void) { return a; }' \
  | $RUN_HOST $CCLINK -xc - -o tlstest > /dev/null 2>&1 || exit 77
if [ "x$CROSS" = "x" ]; then
 ( $RUN LD_LIBRARY_PATH=. ./tlstest || { rm -f tlstest; exit 77; } ) 2>/dev/null || exit 77
fi
rm -f tls2 tls2lib*.so tls2.log
rm -f prelink.cache
$RUN_HOST $CC -shared -O2 -fpic -o tls2lib1.so $srcdir/tls2lib1.c
$RUN_HOST $CC -shared -O2 -fpic -o tls2lib2.so $srcdir/tls1lib2.c tls2lib1.so
BINS="tls2"
LIBS="tls2lib1.so tls2lib2.so"
$RUN_HOST $CCLINK -o tls2 $srcdir/tls2.c -Wl,--rpath-link,. tls2lib2.so -lc tls2lib1.so
savelibs
echo $PRELINK ${PRELINK_OPTS--vm} ./tls2 > tls2.log
$RUN_HOST $PRELINK ${PRELINK_OPTS--vm} ./tls2 >> tls2.log 2>&1 || exit 1
grep -v 'has undefined non-weak symbols' tls2.log \
  | grep -q ^`echo $PRELINK | sed 's/ .*$/: /'` && exit 2
if [ "x$CROSS" = "x" ]; then
 $RUN LD_LIBRARY_PATH=. ./tls2 || exit 3
fi
$RUN_HOST $READELF -a ./tls2 >> tls2.log 2>&1 || exit 4
# So that it is not prelinked again
chmod -x ./tls2
comparelibs >> tls2.log 2>&1 || exit 5
