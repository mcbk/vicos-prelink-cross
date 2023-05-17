#!/bin/bash
. `dirname $0`/functions.sh
rm -f undo1 undo1lib*.so undo1.log
rm -f prelink.cache
$RUN_HOST $CC -shared -O2 -fpic -o undo1lib1.so $srcdir/reloc1lib1.c
$RUN_HOST $CC -shared -O2 -fpic -o undo1lib2.so $srcdir/reloc1lib2.c undo1lib1.so
BINS="undo1"
LIBS="undo1lib1.so undo1lib2.so"
$RUN_HOST $CCLINK -o undo1 $srcdir/reloc1.c -Wl,--rpath-link,. undo1lib2.so -lc undo1lib1.so
savelibs
echo $PRELINK ${PRELINK_OPTS--vm} ./undo1 > undo1.log
$RUN_HOST $PRELINK ${PRELINK_OPTS--vm} ./undo1 >> undo1.log 2>&1 || exit 1
grep -q ^`echo $PRELINK | sed 's/ .*$/: /'` undo1.log && exit 2
if [ "x$CROSS" = "x" ]; then
 $RUN LD_LIBRARY_PATH=. ./undo1 || exit 3
fi
$RUN_HOST $READELF -a ./undo1 >> undo1.log 2>&1 || exit 4
# So that it is not prelinked again
chmod -x ./undo1
echo $PRELINK -uo undo1.undo undo1 >> undo1.log
$RUN_HOST $PRELINK -uo undo1.undo undo1 >> undo1.log 2>&1 || exit 5
cmp -s undo1.undo undo1.orig >> undo1.log 2>&1 || exit 6
rm -f undo1.undo
comparelibs >> undo1.log 2>&1 || exit 7
