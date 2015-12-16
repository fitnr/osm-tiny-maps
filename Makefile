# osm-tiny-maps, OpenStreetMap downloads and image-creation
# Copyright (C) 2015, Neil Freeman

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

PREFIX = .

include config.ini 

# Overpass API endpoint
API ?= http://overpass-api.de/api/interpreter
CURLFLAGS = -s

# List of locations to target for download
LOCATIONS = $(shell $(JQ) keys[] $(BOUNDSFILE))

# valid options: ids, body, skel, tags, meta
VERBOSITY ?= skel

# default configuration file for ogr2ogr
OSM_CONFIG_FILE ?= osm.ini
OSM_USE_CUSTOM_INDEXING = NO
export OSM_CONFIG_FILE OSM_USE_CUSTOM_INDEXING
OGRFLAGS = -lco ENCODING=UTF-8

ENV = .env/bin
JQ = jq --raw-output
CONVERT = convert
RESTYLE = $(ENV)/svgis style
DRAW = $(ENV)/svgis draw

# png files to generate
PNGS = $(addsuffix .png,$(addprefix $(PREFIX)/png/,$(LOCATIONS)))

SCALE = 20

DENSITY = 576

BORDER = 10
REPAGEFLAGS = -trim +repage
BORDERFLAGS = -bordercolor white -border $(BORDER)x$(BORDER)

DRAWFLAGS = --no-viewbox
STYLE = style.css

TASKS = qls osms shps geojsons svgs pngs epss

.PHONY: all install clean $(TASKS)

all: info
info:
	@echo config file: $(OSM_CONFIG_FILE)
	@echo query template: $(QUERYFILE)
	@echo bounds file: $(BOUNDSFILE)
	@echo bounds count: $(words $(LOCATIONS))
	@echo available commands: $(TASKS)

pngs: $(PNGS)

.SECONDEXPANSION:
qls osms epss shps geojsons svgs: %s: $(addsuffix .$$*,$(addprefix $(PREFIX)/%/,$(LOCATIONS)))

$(PREFIX)/png/%.png: $(PREFIX)/svg/%.svg | $(PREFIX)/png
	$(CONVERT) $< -density $(DENSITY) $(REPAGEFLAGS) $(BORDERFLAGS) $@

$(PREFIX)/eps/%.eps: $(PREFIX)/svg/%.svg | $(PREFIX)/eps
	$(CONVERT) $< $(REPAGEFLAGS) $@

# could also be geojson
GEO = shp
FMT.geojson = GeoJSON
FMT.shp = "ESRI Shapefile"

$(PREFIX)/svg/%.svg: $(PREFIX)/$(GEO)/%.$(GEO) $(STYLE) | $(PREFIX)/svg
	$(DRAW) --project local --padding 10 --scale $(SCALE) --style $(STYLE) $(DRAWFLAGS) $< -o $@

$(PREFIX)/shp/%.shp $(PREFIX)/geojson/%.geojson: $(PREFIX)/osm/%.osm | $$(@D)
	@rm -f $@
	ogr2ogr -f $(FMT$(suffix $@)) $(OGRFLAGS) $@ $^ lines

.PRECIOUS: osm/%.osm
$(PREFIX)/osm/%.osm: $(PREFIX)/ql/%.ql | $(PREFIX)/osm
	curl $(API) $(CURLFLAGS) -o $@ --data @$<

$(PREFIX)/ql/%.ql: | $(PREFIX)/ql
	read BBOX <<<$$($(JQ) '.$* | [.miny, .minx, .maxy, .maxx] | map(tostring) | join(",")' $(BOUNDSFILE)); \
	sed -e "s/{{bbox}}/$${BBOX}/g;s/{{verbosity}}/$(VERBOSITY)/g" $(QUERYFILE) > $@

ql osm svg shp geojson png: ; mkdir -p $@

# Clean and install

clean: ; rm -rf ql osm svg shp geojson eps png

install: | $(ENV)/activate
	which gdalinfo || brew install gdal
	. $|; \
		pip list | grep svgis || pip install -r requirements.txt
	which $(CONVERT) || brew install Caskroom/cask/xquartz imagemagick
	which jq || brew install jq

$(ENV)/activate:
	virtualenv $(shell dirname $(ENV))
