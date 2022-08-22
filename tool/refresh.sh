#! /bin/bash
set -e

[[ $0 != 'tool/refresh.sh' ]] && echo "Must be run as tool/refresh.sh" && exit

dart pub get

temp=$(mktemp -d -t tzdata-XXXXXXXXXX)

pushd $temp > /dev/null

echo "Fetching latest database..."
curl https://data.iana.org/time-zones/tzdata-latest.tar.gz | tar -zx

echo "Compiling into zoneinfo files..."
mkdir zoneinfo
zic -d zoneinfo africa antarctica asia australasia etcetera europe \
                northamerica southamerica backward

popd > /dev/null

mkdir -p lib/data

# Pass the zoneinfo directory to the encoding script
dart tool/encode_tzf.dart --zoneinfo $temp/zoneinfo

rm -r $temp

# Create the source embeddings
for scope in latest latest_all latest_10y; do
  echo "Creating embedding: $scope..."
  dart tool/encode_dart.dart lib/data/$scope.{tzf,dart}
done

dart format lib/data
