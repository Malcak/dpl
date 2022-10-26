#!/bin/bash

option_helper() {
    printf "  %s %s\n %s. %s\n\n" "$1" "$2" "$3" "$4"
}

help() {
    printf "USAGE: %s [OPTIONS...]\n\n" "$0"
    printf "OPTIONS:\n\n"
    option_helper "--all" "" "Displays the IP addresses and symbolic names of all hosts in the current subnet" ""
    option_helper "--target" "[IP]" "Displays a list of open system TCP ports from target IP" ""
    option_helper "-h | --help" "" "Displays the help message" ""
}

netmask_to_prefix() {
    echo $1 | awk '
        function count1s(N) {
            c = 0
            for(i=0; i<8; ++i) if(and(2**i, N)) ++c
            return c
        }
        function subnetmaskToPrefix(subnetmask) {
            split(subnetmask, v, ".")
            return count1s(v[1]) + count1s(v[2]) + count1s(v[3]) + count1s(v[4])
        }
        {
            print("/" subnetmaskToPrefix($1))
        }'
}

get_netid_current_if() {
    default_if="$(netstat -nr | head -n 3 | awk '{ print $8 }' | tail -n 1)"
    netmask="$(netstat -nr | grep "$default_if$" | awk '{ print $3 }' | tail -n 1)"
    netmask_prefix="$(netmask_to_prefix $netmask)"
    echo "$(netstat -nr | grep "$default_if$" | awk '{ print $1 }' | tail -n 1)$netmask_prefix"
}

print_net_hosts() {
    if [[ ! $1 ]]; then
        SUBNET="$(get_netid_current_if)"
    else
        SUBNET="$1"
    fi

    readonly HOSTS="$(nmap -sn -n $SUBNET | awk '/report / { print $5 }')"
    for IP in $HOSTS; do
        HOST_NAME_RESOLVE="$(host $IP | head -n 1)"
        HOST_NAME="$(echo $HOST_NAME_RESOLVE | awk '{ print $5 }')"
        if [[ "$HOST_NAME" == "3(NXDOMAIN)" ]]; then
            HOST_NAME=""
        fi
        printf "%s %s\n" "$IP" "$HOST_NAME"
    done
}

print_open_tcp_ports() {
    if [[ ! $1 ]] || [[ $1 == "-" ]]; then
        target_host="localhost"
    else
        target_host="$1"
    fi

    echo "$(nmap -T4 $target_host -p-)"
}

if [[ $# -eq 0 ]]; then
    echo "No arguments provided."
    has_arguments="false";
fi

# argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in

        --all)
            display_subnet="true"; shift ;;
        --target)
            if [[ ! $2 ]]; then
                echo "Missing target IP. localhost will be used instead"
                display_open_tcp_ports="true"; target_ip="localhost"; shift;
            else
                display_open_tcp_ports="true"; target_ip="$2"; shift 2;
            fi
            ;;
        -h|--help)
            need_help="true"; shift ;;
        "")
            shift ;;
        *)
            echo "Unrecognized option '$1'."
            has_any_error="true"; shift ;;
    esac
done

if [[ "$has_any_error" == "true" ]] || [[ "${has_arguments}" == "false" ]]; then
    help
    exit 1
fi

if [[ "$need_help" == "true" ]]; then
    help
    exit 0
fi

if [[ "$display_subnet" == "true" ]]; then
    SUBNET="$(get_netid_current_if)"
    print_net_hosts $SUBNET
fi

if [[ "$display_open_tcp_ports" == "true" ]]; then
    print_open_tcp_ports $target_ip
fi