#!/bin/bash

#Wall         - 5 6 7
#Sectional    -       8 9 10 11 
#Terminal/GC  -	          10 11 
#Enroute_low  -       8 9 10 11

BASE="/Volumes/NFS/chartmaker"
cd $BASE/chartmaker

# Sectional
echo "Sectional Start"
cp settings.json.Sectional settings.json
node make -full-single=0
echo "Sectional Complete"

# Terminal
echo "Terminal Start"
#cp settings.json.Terminal settings.json
#node make -full-single=3
echo "Terminal Complete"

# Grand Canyon
echo "Grand Canyon Start"
cp settings.json.GC settings.json
node make -full-single=2
echo "Grand Canyon Complete"

# Enroute Low
echo "IFR Start"
cp settings.json.Sectional settings.json
node make -full-single=5
echo "IFR Complete"


#echo "FIXING permissions"
#sudo chown -R michaelkuriger:staff $BASE/chartmaker/workarea
echo "Done"
