#!/bin/bash
. `dirname $0`/functions.sh
rm -f cycle1 cycle1lib*.so cycle1.log
rm -f prelink.cache
# Test whether prelink doesn't segfault or loop endlessly on
# bogus library dependency chains
echo 'int foo;' | $RUN_HOST $CC -shared -O2 -fpic -o cycle1lib1.so -xc -
echo 'int bar;' | $RUN_HOST $CC -shared -O2 -fpic -o cycle1lib2.so -xc - -xnone cycle1lib1.so
echo 'int foo;' | $RUN_HOST $CC -shared -O2 -fpic -o cycle1lib1.so -xc - -xnone cycle1lib2.so
BINS="cycle1"
LIBS="cycle1lib1.so cycle1lib2.so"
echo 'int main (void) { return 0; } ' \
  | $RUN_HOST $CCLINK -o cycle1 -xc - -xnone -Wl,--rpath-link,. cycle1lib2.so
savelibs
echo $PRELINK ${PRELINK_OPTS--vm} ./cycle1 > cycle1.log
$RUN_HOST $PRELINK ${PRELINK_OPTS--vm} ./cycle1 >> cycle1.log 2>&1 || exit 1
grep -v 'has a dependency cycle' cycle1.log \
  | grep -q ^`echo $PRELINK | sed 's/ .*$/: /'` && exit 2
grep -q "^`echo $PRELINK | sed 's/ .*$/: .*has a dependency cycle/'`" \
  cycle1.log || exit 3
if [ "x$CROSS" = "x" ] ; then
 $RUN LD_LIBRARY_PATH=. ./cycle1 || exit 4
fi
# So that it is not prelinked again
chmod -x ./cycle1
