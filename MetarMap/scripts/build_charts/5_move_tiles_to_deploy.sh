#!/bin/bash

BASE="/Volumes/NFS/chartmaker"

[ -d "$BASE/chartmaker/workarea/Sectional/6_quantized" ] || { echo "Missing Sectional, make sure to generate tiles first"; exit 1; }
[ -d "$BASE/chartmaker/workarea/Terminal/6_quantized" ] || { echo "Missing Terminal, make sure to generate tiles first"; exit 1; }
[ -d "$BASE/chartmaker/workarea/Enroute_Low/6_quantized" ] || { echo "Missing Enroute_Low, make sure to generate tiles first"; exit 1; }

# remove previous backup
/bin/rm -rf $BASE/metarmap/Sectional.pre
/bin/rm -rf $BASE/metarmap/Terminal.pre
/bin/rm -rf $BASE/metarmap/Enroute_Low.pre

# cleanup
#find $BASE/chartmaker/workarea/Sectional/6_quantized -name "*.xml" -exec /bin/rm {} \;
#find $BASE/chartmaker/workarea/Terminal/6_quantized -name "*.xml" -exec /bin/rm {} \;
#find $BASE/chartmaker/workarea/Enroute_Low/6_quantized -name "*.xml" -exec /bin/rm {} \;

# backup current charts
/bin/rm -rf $BASE/Sectional.old $BASE/Terminal.old $BASE/Enroute_Low.old
/bin/mv -f $BASE/metarmap/Sectional $BASE/Sectional.old
/bin/mv -f $BASE/metarmap/Terminal $BASE/Terminal.old
/bin/mv -f $BASE/metarmap/Enroute_Low $BASE/Enroute_Low.old

# move new charts into place
/bin/mv $BASE/chartmaker/workarea/Sectional/6_quantized $BASE/metarmap/Sectional
/bin/mv $BASE/chartmaker/workarea/Terminal/6_quantized $BASE/metarmap/Terminal
/bin/mv $BASE/chartmaker/workarea/Enroute_Low/6_quantized $BASE/metarmap/Enroute_Low
