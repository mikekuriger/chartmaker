export NETLIFY_AUTH_TOKEN=nfp_uWFtXikwzwZVuMG4quCDbF1rQCUbpsMae3c1
export NODE_OPTIONS="--max-old-space-size=8192"
BASE="/Volumes/NFS/chartmaker"
cd $BASE/metarmap/
netlify deploy --prod --dir=.

# log in via github
