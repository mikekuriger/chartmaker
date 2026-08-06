#!/bin/bash

BASE="/Volumes/NFS/chartmaker"
cd $BASE/chartmaker

# Grand Canyon
echo "Grand Canyon Start"
cp settings.json.GC settings.json

#sudo docker run --rm --platform linux/amd64 \
#  -v $BASE/chartmaker:/chartmaker:z \
#  -w /chartmaker \
#  chartmaker:1 \
#  bash -lc '/root/.nvm/versions/node/v22.14.0/bin/node make -full-single=2'

node make -full-single=2

echo "Grand Canyon Complete"

echo "FIXING permissions"
sudo chown -R michaelkuriger:staff $BASE/chartmaker/workarea
echo "Done"
