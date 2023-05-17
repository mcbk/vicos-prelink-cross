#!/bin/bash
. `dirname $0`/functions.sh
rm -f reloc1 reloc1lib*.so reloc1.log
rm -f prelink.cache
$RUN_HOST $CC -shared -O2 -fpic -o reloc1lib1.so $srcdir/reloc1lib1.c
$RUN_HOST $CC -shared -O2 -fpic -o reloc1lib2.so $srcdir/reloc1lib2.c reloc1lib1.so
BINS="reloc1"
LIBS="reloc1lib1.so reloc1lib2.so"
$RUN_HOST $CCLINK -o reloc1 $srcdir/reloc1.c -Wl,--rpath-link,. reloc1lib2.so -lc reloc1lib1.so
savelibs
echo $PRELINK ${PRELINK_OPTS--vm} ./reloc1 > reloc1.log
$RUN_HOST $PRELINK ${PRELINK_OPTS--vm} ./reloc1 >> reloc1.log 2>&1 || exit 1
grep -q ^`echo $PRELINK | sed 's/ .*$/: /'` reloc1.log && exit 2
if [ "x$CROSS" = "x" ]; then
 $RUN LD_LIBRARY_PATH=. ./reloc1 || exit 3
fi
$RUN_HOST $READELF -a ./reloc1 >> reloc1.log 2>&1 || exit 4
# So that it is not prelinked again
chmod -x ./reloc1
comparelibs >> reloc1.log 2>&1 || exit 5
