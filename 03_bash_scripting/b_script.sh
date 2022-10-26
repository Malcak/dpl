#!/bin/bash

option_helper() {
    printf "  %s %s\n %s. %s\n\n" "$1" "$2" "$3" "$4"
}

help() {
    printf "USAGE: %s [PATH_TO_LOGS]\n\n" "$0"
    printf "OPTIONS:\n\n"
    option_helper "-h | --help" "" "Displays the help message" ""
}

get_ip_with_the_most_requests() {
    cat $1 | awk '{print $1}' | sort | uniq -c | sort -gr | head -n 1 | xargs echo
}

get_most_requested_page() {
    cat $1 | awk '{print $7}' | sort | uniq -c | sort -gr | head -n 1 | xargs echo
}

get_request_per_ip() {
    cat $1 | awk '{print $1}' | sort | uniq -c | sort -gr
}

get_non_existent_pages_requested() {
    cat $1 | awk '$9==302  {print $7}' | sort | uniq
}

get_request_per_time() {
    cat $1 | grep -Eo '[0-9]{2}\/[a-zA-Z]{3}\/[0-9]{4}(:[0-9]{2}){3}' | sort | uniq -c | sort -gr
}

get_searchbots() {
    cat $1 | awk '
        BEGIN { 
            OFS = "\t"
        }
        { 
            for(i=1;i<=NF;i++) { 
                if( $i ~ /([^\s]+)[Bb]ot([^\s]+);/ ) {
                    print $1,$i 
                } 
            } 
        }' | sort | uniq
}

if [[ $# -eq 0 ]]; then
    echo "The path to the log file is mandatory."
    has_any_error="true";
fi

if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help) need_help="true";;
        "") 
            echo "The path is not valid."
            has_any_error="true";;
        *) 
            if [[ ! -f $1 ]]; then
                has_any_error="true"
            else
                path="$1"
            fi
        ;;
    esac
fi

if [[ "$has_any_error" == "true" ]]; then
    help
    exit 1
fi

if [[ "$need_help" == "true" ]]; then
    help
    exit 0
fi

printf "\nFrom which ip were the most requests?\n"
get_ip_with_the_most_requests  $path
printf "\nWhat is the most requested page?\n"
get_most_requested_page $path
printf "\nHow many requests were there from each IP?\n"
get_request_per_ip $path
printf "\nWhat non-existent pages were clients referred to?\n"
get_non_existent_pages_requested $path
printf "\nWhat time did site get the most requests?\n"
get_request_per_time $path
printf "\nWhat search bots have accessed the site?\n"
get_searchbots $path