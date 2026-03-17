##### Get local fuel prices (fuel_prices) 1.0

Downloads the goverments fuel data and greps it based on first two charicters in your postcode then mesures the distance in km from your latitude and longitude. 
Then sorts the results low to high and displays the prices. It also records an ongoing log of all historic prices it has fetched.

###### Usage

```
./fuel_prices [OPTION]
```

With no options it will default to the center of the UK, 4km radius, sort by petrol and output to a folder called fuel_price_data.

Options are...

```
    -s      Sort by the column number in the cache, (2) Trading Name, (6) Petrol or (7) Diesel prices.
    -p      First characters of your postcode.
                Note, this will speed up the process by text filtering the data first
                instead of using distance calculations on every station in the UK.

    -lat    Your latitude.
    -lng    Your longitude.
    -d      Sets max distance from your location in km.

            Example...
                ./fuel_prices -p BB -lat 53.825564 -lng -2.421975 -d 4 -o Documents/fuel_price_data -s 7

    -f      Force an update, regardless of if the file has expired. It expires every 12 hours.
            Because of the cache, if you change location you need to force an update or wait 12 hours.
    -o      Output folder, where it saves all data files.
```

Feel free to do with this as you please, but I take no responsibility for its use or functionality. That said...

Any bugs or pointers... <script@rubbermonkeys.co.uk>.
