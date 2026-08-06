#!/bin/bash

BASE="/Volumes/NFS/chartmaker"

cd $BASE/chartmaker/workarea

for i in `ls`; do echo $i; cd $BASE/chartmaker/workarea/$i; time rm -rf 1_unzipped  2_expanded  3_clipped  4_tiled  5_merged; done

