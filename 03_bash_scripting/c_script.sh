check_path_error() {
    if [[ -z $1 ]] || [[ ! -f $1 ]] && [[ ! -d $1 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

if [[ $# -eq 0 ]]; then
    echo "The paths to the source and to the destination are missing."
    has_any_error="true"
fi

if [[ $# -eq 2 ]]; then
    has_source_errors="$(check_path_error $1)"
    has_dest_errors="$(check_path_error $2)"

    if [[ $has_source_errors == "true" ]]; then
        echo "The source path is invalid."
        has_any_error="true"
    fi

    if [[ $has_dest_errors == "true" ]]; then
        echo "The dest path is invalid."
        has_any_error="true"
    fi

    if [[ $1 == $2 ]]; then
        echo "The paths cannot be the same."
        has_any_error="true"
    fi
else
    echo "Exactly 2 arguments were expected."
    has_any_error="true"
fi

if [[ "$has_any_error" == "true" ]]; then
    exit 1
fi

if [[ ! -d "/var/log/backup_script/" ]]; then
    sudo mkdir -p "/var/log/backup_script/"
fi

sudo rsync -ahruvz --mkpath --delete --log-file-format="%o %i %f%L" --log-file="/var/log/backup_script/report.log" $1 $2