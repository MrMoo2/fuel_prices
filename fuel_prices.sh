#!/bin/bash

# Author: MrMoo
# Date Created: 2026-03-12
# Last Modified: 2026-03-23

# Notes: 
#       Petrol (E10), Super (E5), Diesel (B7), Super Diesel
#       AWK may be better for parsing csv, but more complex though.

# TODO:5 Error checking for the param values
# TODO:7 Make the compare work as a function...
#           The issue is the array gets passed in and split on the spaces (I think)
#           Like the doggy hack when reading the old cache

# --------------------------------------------------------
# Show help or version details
# --------------------------------------------------------
version="Get local fuel prices (fuel_prices) 1.1

Written by MrMoo."

usage="Usage: $0 [OPTION]...
Downloads the governments fuel data and greps it based on first two characters in your postcode then measures the distance in km from your latitude and longitude.
Then sorts the results low to high and displays the prices. It also records an ongoing log of all historic prices it has fetched.

With no options it will default to the center of the UK, 4km radius, sort by diesel and output to a folder called fuel_price_data.

Options are...
    -s      Sort by the column number in the cache, (2) Trading Name, (6) Petrol or (7) Diesel prices.
    -p      First characters of your postcode.
                Note, this will speed up the process by text filtering the data first
                instead of using distance calculations on every station in the UK.

    -lat    Your latitude.
    -lng    Your longitude.
    -d      Sets max distance from your location in km.

            Example...
                $0 -p BB -lat 53.825564 -lng -2.421975 -d 4 -o Documents/fuel_price_data -s 7

    -f      Force an update, regardless of if the file has expired. It expires every 12 hours.
            Because of the cache, if you change location you need to force an update or wait 12 hours.
    -o      Output folder, where it saves all data files.

    -c      Disable output with colour escape codes.

Feel free to do with this as you please, but I take no responsibility for its use or functionality. That said...

Any bugs or pointers... <script@rubbermonkeys.co.uk>."

not_known="Unrecognised parameter"

case $1 in
--help)      printf '%s\n' "$usage"   || exit 1; exit;;
-h)          printf '%s\n' "$usage"   || exit 1; exit;;
--version)   printf '%s\n' "$version" || exit 1; exit;;
-v)          printf '%s\n' "$version" || exit 1; exit;;
esac
# --------------------------------------------------------



# --------------------------------------------------------
# Hard Coded Configuration (center of UK)
# --------------------------------------------------------
number_of_seconds_to_get_new_data=43200 # 12 Hours
local_quick_filter="BB[0-9]\{1,2\}\s"
max_distance=4.0
my_latitude=53.825564
my_longitude=-2.421975
output_folder="fuel_price_data"
sort_by=7
disable_colour=0
# --------------------------------------------------------


# --------------------------------------------------------
# Loop through all the parameters and deal with them
# --------------------------------------------------------
read_sortby=0
read_postcode=0
read_lat=0
read_lng=0
read_distance=0
read_folder=0
params=("$@")
for param in "${params[@]}"; do
    # Get number to show from parameters
    if [ $read_postcode = 1 ]; then
        local_quick_filter="$param[0-9]\{1,2\}\s"
        read_postcode=0
    elif [ $read_lat = 1 ]; then
        my_latitude=$param
        read_lat=0
    elif [ $read_lng = 1 ]; then
        my_longitude=$param
        read_lng=0
    elif [ $read_distance = 1 ]; then
        max_distance=$param
        read_distance=0
    elif [ $read_folder = 1 ]; then
        output_folder=$param
        read_folder=0
    elif [ $read_sortby = 1 ]; then
        sort_by=$param
        read_sortby=0
    
    # Next one will be a date
    elif [ $param = "-p" ]; then
        read_postcode=1
    elif [ $param = "-lat" ]; then
        read_lat=1
    elif [ $param = "-lng" ]; then
        read_lng=1
    elif [ $param = "-d" ]; then
        read_distance=1
    elif [ $param = "-f" ]; then
        number_of_seconds_to_get_new_data=0
    elif [ $param = "-o" ]; then
        read_folder=1
    elif [ $param = "-s" ]; then
        read_sortby=1
    elif [ $param = "-c" ]; then
        disable_colour=1
    
    # Not a recognised parameter so show help
    else
        echo "$not_known"; echo "$usage"; exit 1; exit;
    fi
done
# --------------------------------------------------------


# --------------------------------------------------------
# Initialisation 
# --------------------------------------------------------
cache_file="$output_folder/cache.txt"                           # Cache file for speed and not spamming
cache_file_old="$output_folder/cache_old.txt"                   # Cache file for comparing to last prices
download_file="$output_folder/full_uk_fuel_prices.csv"          # Complete downloaded data
local_filtered_file="$output_folder/localised_fuel_prices.csv"  # First basic text filter on the file
clean_file="$output_folder/localised_fuel_prices_clean.csv"     # Cleaned file, easier for parsing, but loses some data
data_file="$output_folder/fuel_price_data_history.csv"          # Historic data for seeing details

# Used to extract the data in the while loop, each one will become a variable
col_header_string="forecourt_update_timestamp node_id trading_name brand_name is_motorway_service_station is_supermarket_service_station public_phone_number temporary_closure permanent_closure permanent_closure_date postcode address_line_1 address_line_2 city county country latitude longitude fuel_price_E5 price_submission_timestamp_E5 price_change_effective_timestamp_E5 fuel_price_E10 price_submission_timestamp_E10 price_change_effective_timestamp_E10 fuel_price_B7S price_submission_timestamp_B7S price_change_effective_timestamp_B7S fuel_price_B7P price_submission_timestamp_B7P price_change_effective_timestamp_B7P fuel_price_B10 price_submission_timestamp_B10 price_change_effective_timestamp_B10  fuel_price_HVO price_submission_timestamp_HVO price_change_effective_timestamp_HVO opening_times_monday_open_time opening_times_monday_close_time opening_times_monday_is_24_hours opening_times_tuesday_open_time opening_times_tuesday_close_time opening_times_tuesday_is_24_hours opening_times_wednesday_open_time opening_times_wednesday_close_time opening_times_wednesday_is_24_hours opening_times_thursday_open_time opening_times_thursday_close_time opening_times_thursday_is_24_hours opening_times_friday_open_time opening_times_friday_close_time opening_times_friday_is_24_hours opening_times_saturday_open_time opening_times_saturday_close_time opening_times_saturday_is_24_hours opening_times_sunday_open_time opening_times_sunday_close_time opening_times_sunday_is_24_hours opening_times_bank_holiday_standard_open_time opening_times_bank_holiday_standard_close_time opening_times_bank_holiday_standard_is_24_hours amenities_fuel_and_energy_services_adblue_pumps amenities_fuel_and_energy_services_adblue_packaged amenities_fuel_and_energy_services_lpg_pumps amenities_vehicle_services_car_wash amenities_air_pump_or_screenwash amenities_water_filling amenities_twenty_four_hour_fuel amenities_customer_toilets"
cache_col_header_string="output_date trading_name brand_name latitude longitude fuel_price_E10 fuel_price_B7S"

update_data=0
has_cache=1

counter=0
cache_output=""
storage_output=""
console_output=""

E10_out_start=""
B7S_out_start=""

if [ $disable_colour == 0 ]; then
    col_petrol="\e[92m"     # Green
    col_diesel="\e[35m"     # Purple
    col_good="\e[92m"       # Green
    col_bad="\e[31m"        # Red
    col_end="\e[0m"         # Escape end
fi

OLD_IFS=$IFS
# --------------------------------------------------------


# --------------------------------------------------------
# Functions
# --------------------------------------------------------
# Degrees to Radians
deg2rad() {
    echo "$1 * 0.0174532925" | bc -l
}

# The Haversine formula 
# Is used to calculate the great-circle distance between two points on a sphere based on their longitudes and latitudes.
haversine() {
    lat1=$(deg2rad $1)
    lon1=$(deg2rad $2)
    lat2=$(deg2rad $3)
    lon2=$(deg2rad $4)

    delta_lat=$(echo "$lat2 - $lat1" | bc -l)
    delta_lon=$(echo "$lon2 - $lon1" | bc -l)

    a=$(echo "s($delta_lat/2)^2 + c($lat1) * c($lat2) * s($delta_lon/2)^2" | bc -l)
    c=$(echo "2 * a( sqrt($a) / sqrt(1-$a) )" | bc -l)
    r=6371 # Radius of Earth in kilometres (approximately)
    distance=$(echo "$r * $c" | bc -l | awk '{printf "%f", $0}') # Added awk to bring down the number

    echo $distance
}

difference_formatted() {
    difference=$((echo "$1 - $2") | bc -l | awk '{printf "%.2f", $0}')
    if [[ $((echo "$1 < $2") | bc -l) == 1 ]]; then
        echo "($difference)"
    elif [[ $((echo "$1 > $2") | bc -l) == 1 ]]; then
        echo "(+$difference)"
    else
        echo "       " # Dirty output for position
    fi
}
# --------------------------------------------------------


# --------------------------------------------------------
# Sort out files and directories
# --------------------------------------------------------

# Make the directory if it does not exist
if [ ! -d "$output_folder" ]; then mkdir $output_folder; fi

# Get the age of the data file
# -----------------------------------------
if [ -f $download_file ]; then
    download_date=$(date -r $download_file +%s)
else
    download_date=0
fi
current_date=$(date +%s)
number_of_seconds=$(($current_date-$download_date))

# If old data get new
# -----------------------------------------
if [[ $number_of_seconds -gt $number_of_seconds_to_get_new_data ]]; then
    update_data=1
    has_cache=0
    # Download the fuel price csv from the gov, with follow redirects and save to a file
    curl -L https://www.fuel-finder.service.gov.uk/internal/v1.0.2/csv/get-latest-fuel-prices-csv -o $download_file > /dev/null 2>&1
    # New file update the date for output
    download_date=$(date -r $download_file +%s)
fi
output_date=$(date -d "@$download_date" +'%Y-%m-%d %H:%M:%S')

# Do cache and data files exist
# -----------------------------------------
# There is no history
if [ ! -f $data_file ]; then
    update_data=1
    storage_output="\"Date_Time\",\"Trading_Name\",\"Brand_Name\",\"Latitude\",\"Longitude\",\"Petrol_Price\",\"Diesel_Price\"\n"
fi
# There is no cache
if [ ! -f $cache_file ]; then
    has_cache=0
fi
# --------------------------------------------------------



# --------------------------------------------------------
# Generate the data
# --------------------------------------------------------
if [ $has_cache == 0 ]; then

    # Filter it down a bit for speed
    # -----------------------------------------
    # Grep based on local postcodes
    grep -e $local_quick_filter $download_file > $local_filtered_file

    # Clean the file e.g. Drop all the quoted values
    while read line; do
        #echo "Record: $line"
        echo $line | awk '{gsub(/,".*?",/, ",NA,"); print}'
    done < $local_filtered_file > $clean_file
    # -----------------------------------------


    # Loop through what we are left with
    # -----------------------------------------
    while IFS="," read -r $col_header_string; do

        # Get the distance to the petrol station
        distance=$(haversine $my_latitude $my_longitude $latitude $longitude)
        in_area=$(echo "$distance < $max_distance" | bc -l)

        # In our local
        if [[ $in_area == 1 ]]; then
            # Has fuel, not EV
            if [[ -n $fuel_price_E10 ]]; then
                counter=$(($counter+1))
                storage_output+="\"$output_date\",\"$trading_name\",\"$brand_name\",\"$latitude\",\"$longitude\",\"$fuel_price_E10\",\"$fuel_price_B7S\"\n"
                cache_output+="$output_date,$trading_name,$brand_name,$latitude,$longitude,$fuel_price_E10,$fuel_price_B7S\n"
            fi
        fi

    #done < <(tail -n +2 $clean_file) # Don't understand!!!! why add tail
    done < $clean_file
    # -----------------------------------------

    # cut off the last \n
    # -----------------------------------------
    storage_output=${storage_output:0:${#storage_output}-2}
    cache_output=${cache_output:0:${#cache_output}-2}
    # -----------------------------------------

    # Make the cache and sort it
    # -----------------------------------------

    # Cache the old cache if there is one
    if [ -f $cache_file ]; then
        cp "$cache_file" "$cache_file_old"
    fi

    # Build the cache
    echo -e "$cache_output" > $cache_file
    sort -t "," -n -k $sort_by $cache_file > "$cache_file.tmp"
    cp "$cache_file.tmp" $cache_file
    rm "$cache_file.tmp"

    # We don't have an old cache so just copy what we have
    if [ ! -f $cache_file_old ]; then
        cp "$cache_file" "$cache_file_old"
    fi
    # -----------------------------------------

fi
# --------------------------------------------------------


# --------------------------------------------------------
# Output
# --------------------------------------------------------

# Get the last cache data for comparing
# -----------------------------------------
while IFS=',' read -r $cache_col_header_string; do
    IFS=','
    trading_name_array+=( $(printf "$trading_name") )
    IFS=$OLD_IFS
    fuel_price_E10_array+=( $(printf %.2f "$fuel_price_E10") )
    fuel_price_B7S_array+=( $(printf %.2f "$fuel_price_B7S") )
done < $cache_file_old
# -----------------------------------------

# Get from cache the text tile and loop through what we have
# -----------------------------------------
console_output+=$(printf "%-37s" "")
console_output+="$col_petrol\tPetrol$col_end  \t$col_diesel""Diesel$col_end\n"
while IFS=',' read -r $cache_col_header_string; do

    # Find the last value from the old cache
    found=0
    array_counter=0
    for item in "${trading_name_array[@]}"; do
        if [[ $item == $trading_name ]]; then
            found=1
            break
        fi
        array_counter=$(($array_counter+1))
    done

    # Get a formatted +- difference value from the last cache if its not new
    if [[ $found == 1 ]]; then
        fuel_price_E10_val_diff=$(difference_formatted $fuel_price_E10 ${fuel_price_E10_array[$array_counter]})
        fuel_price_B75_val_diff=$(difference_formatted $fuel_price_B7S ${fuel_price_B7S_array[$array_counter]})
    else
        fuel_price_E10_val_diff=$(difference_formatted 0 0)
        fuel_price_B75_val_diff=$(difference_formatted 0 0)
    fi

    # Do we have colour enabled
    E10_out_start=""
    B7S_out_start=""
    if [ $disable_colour == 0 ]; then
        if [[ $fuel_price_E10_val_diff == *"-"* ]]; then
            E10_out_start=$col_good
        elif [[ $fuel_price_E10_val_diff == *"+"* ]]; then
            E10_out_start=$col_bad
        fi

        if [[ $fuel_price_B75_val_diff == *"-"* ]]; then
            B7S_out_start=$col_good
        elif [[ $fuel_price_B75_val_diff == *"+"* ]]; then
            B7S_out_start=$col_bad
        fi
    fi

    # Construct the output
    console_output+=$(printf "%-30s" "$trading_name")"\t"
    console_output+="$E10_out_start$fuel_price_E10_val_diff$col_end "$(printf %.2f "$fuel_price_E10")"\t"
    console_output+="$B7S_out_start$fuel_price_B75_val_diff$col_end "$(printf %.2f "$fuel_price_B7S")"\n"

done < $cache_file
# -----------------------------------------

# cut off the last \n
console_output=${console_output:0:${#console_output}-2}

echo -e "$console_output"
if [ $update_data == 1 ]; then
    echo -e "$storage_output" >> $data_file # Append historic data (if changed)
fi
# --------------------------------------------------------

IFS=$OLD_IFS
exit 0
