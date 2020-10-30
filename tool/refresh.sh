#! /bin/bash
set -e

[[ $0 != 'tool/refresh.sh' ]] && echo "Must be run as tool/refresh.sh" && exit

pub get

temp=$(mktemp -d -t tzdata-XXXXXXXXXX)

pushd $temp > /dev/null

# Fetch latest database
curl https://data.iana.org/time-zones/tzdata-latest.tar.gz | tar -zx

# Compile into zoneinfo files
mkdir zoneinfo
zic -d zoneinfo africa antarctica asia australasia etcetera europe \
                northamerica southamerica backward

popd > /dev/null

mkdir -p lib/data

# Pass the zoneinfo directory to the encoding script
pub run tool/encode_tzf --zoneinfo $temp/zoneinfo

rm -r $temp

# Create the source embeddings
for x in latest latest_all latest_10y; do
  pub run tool/encode_dart lib/data/$x.{tzf,dart}
done
