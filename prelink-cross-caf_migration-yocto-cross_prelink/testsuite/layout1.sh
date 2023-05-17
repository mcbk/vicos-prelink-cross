#!/bin/bash
. `dirname $0`/functions.sh
rm -f prelink.cache
rm -f layout1 layoutlib*.so layout1.log
i=10
BINS="layout1"
LIBS=
while [ $i -lt 74 ]; do
  $RUN_HOST $CXX -shared -fpic -o layout1lib$i.so $srcdir/layoutlib.C
  LIBS="$LIBS layout1lib$i.so"
  i=`expr $i + 1`
done
$RUN_HOST $CXXLINK -o layout1 $srcdir/layout.C layout1lib*.so
savelibs
echo $PRELINK ${PRELINK_OPTS--vR} ./layout1 > layout1.log
$RUN_HOST $PRELINK ${PRELINK_OPTS--vR} ./layout1 >> layout1.log 2>&1 || exit 1
grep -q ^`echo $PRELINK | sed 's/ .*$/: /'` layout1.log && exit 2
if [ "x$CROSS" = "x" ]; then
 $RUN LD_LIBRARY_PATH=. ./layout1 || exit 3
fi
$RUN_HOST $READELF -a ./layout1 >> layout1.log 2>&1 || exit 4
# So that it is not prelinked again
chmod -x ./layout1
comparelibs >> layout1.log 2>&1 || exit 5
