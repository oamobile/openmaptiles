#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

echo " "

import_osm=0
while true; do
read -p "Import OSM to PostgreSQL? (y/n) " yn1
case $yn1 in
        y ) import_osm=1
                break;;
        n ) import_osm=0
                break;;
        * ) echo invalid response;;
esac
done

import_wiki=0
while true; do
read -p "Import Wiki data? (y/n) " yn1
case $yn1 in
        y ) import_wiki=1
                break;;
        n ) import_wiki=0
                break;;
        * ) echo invalid response;;
esac
done

create_boundary=0
while true; do
read -p "Create bbox boundary? (y/n) " yn1
case $yn1 in
        y ) create_boundary=1
                break;;
        n ) create_boundary=0
                break;;
        * ) echo invalid response;;
esac
done

import_sql=0
while true; do
read -p "Import to SQL? (y/n) " yn1
case $yn1 in
        y ) import_sql=1
                break;;
        n ) import_sql=0
                break;;
        * ) echo invalid response;;
esac
done


generate_tiles=0
while true; do
read -p "Generate mbtiles file? (y/n) " yn1
case $yn1 in
        y ) generate_tiles=1
                break;;
        n ) generate_tiles=0
                break;;
        * ) echo invalid response;;
esac
done


setup_tile_svr=0
while true; do
read -p "Setup docker tile server (first install only)? (y/n) " yn1
case $yn1 in
        y ) setup_tile_svr=1
                break;;
        n ) setup_tile_svr=0
                break;;
        * ) echo invalid response;;
esac
done

echo " "
echo "====> : Restarting PostgreSQL"
sudo systemctl restart postgresql

echo " "
echo "====> : Removing /data files"
sudo rm -f *.osm
sudo rm -f *.bbox

echo " "
echo "-------------------------------------------------------------------------------------"
if [[ import_osm -eq 1 ]] 
then
	echo "====> : Start importing OpenStreetMap data: {area} -> imposm3[./build/mapping.yaml] -> PostgreSQL"
	sudo make import-osm
else
	echo "====> : SKIPPING importing OpenStreetMap data"
fi


echo " "
echo "-------------------------------------------------------------------------------------"
if [[ import_wiki -eq 1 ]] 
then
	echo "====> : Start importing Wikidata: Wikidata Query Service -> PostgreSQL"
	sudo make import-wikidata
else
	echo "====> : SKIPPING importing Wiki data"
fi


echo " "
echo "-------------------------------------------------------------------------------------"
if [[ create_boundary -eq 1 ]] 
then
	echo "====> : Compute bounding box for tile generation"
	sudo make generate-bbox-file
else
	echo "====> : SKIPPING calculating boundary box"
fi


echo " "
echo "-------------------------------------------------------------------------------------"
if [[ import_sql -eq 1 ]] 
then
	echo "====> : Start SQL postprocessing:  ./build/sql/* -> PostgreSQL "
	sudo make import-sql
else
	echo "====> : SKIPPING importing to SQL"
fi


echo " "
echo "-------------------------------------------------------------------------------------"
if [[ generate_tiles -eq 1 ]] 
then
	echo "====> : Start generating MBTiles (containing gzipped MVT PBF) using PostGIS. "
	sudo make generate-tiles-pg
else
	echo "====> : SKIPPING generating tiles"
fi

echo " "
echo "-------------------------------------------------------------------------------------"
if [[ setup_tile_svr -eq 1 ]] 
then
	echo "====> : Start docker tile server. "
	sudo docker run --restart=always -it -d -v /home/ubuntu/openmaptiles/data:/data -p 8080:8080 maptiler/tileserver-gl
else
	echo "====> : SKIPPING setting up docker tile server"
fi
