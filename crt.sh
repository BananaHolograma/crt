#!/usr/bin/env bash

declare -g OUTPUT_PATH='./'
declare -i THREADS=10
declare -g CACHE_PATH='.crt-cache'

[[ ! -f "$CACHE_PATH" ]] && mkdir -m 0755 -p "$CACHE_PATH"

function extract_subdomains_from_source() {
    local ROOT_DOMAIN=$1
    local WORK_PATH=$2
    local SUBDOMAIN_PATH=$3
    
    grep -Eo '<TD>[*]?[[:alpha:].-]+</TD>' "$WORK_PATH" | sed -E 's/<\/?TD>//g' | sort -u > "$SUBDOMAIN_PATH"
    echo -e "\033[2K[+] Found $(wc -l "$SUBDOMAIN_PATH" | grep -Eo '[0-9]+') results for $ROOT_DOMAIN"
}

function fetch_subdomains() {
    local ROOT_DOMAIN=$1
    local OUTPUT_PATH=$2
    local CACHE_PATH=$3

    local BASE_FILENAME="${ROOT_DOMAIN}.html"
    local WORK_PATH="$CACHE_PATH/$BASE_FILENAME"
    local SUBDOMAIN_PATH="${OUTPUT_PATH}subdomains_$ROOT_DOMAIN.txt"

    if [[ -n "$ROOT_DOMAIN" && "$ROOT_DOMAIN" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.[a-zA-Z]{2,24}$ ]]; then

        echo -e "[-] Fetching certificate transparency history for domain $ROOT_DOMAIN ..."

        if [[ -f "$WORK_PATH" ]]; then
            extract_subdomains_from_source "$ROOT_DOMAIN" "$WORK_PATH" "$SUBDOMAIN_PATH"
        elif curl --tcp-fastopen --tcp-nodelay --fail -Ls -o "$WORK_PATH" "https://crt.sh/?q=$ROOT_DOMAIN"; then 
            chmod 0755 "$WORK_PATH"                                             
            extract_subdomains_from_source "$ROOT_DOMAIN" "$WORK_PATH" "$SUBDOMAIN_PATH"
        else 
            echo -e "[ FAILED ]The request to https://crt.sh/?q=$ROOT_DOMAIN has failed"
            exit 2
        fi  

    else 
        echo -e "[ ERROR ]Provide a valid domain or subdomain as an argument, $ROOT_DOMAIN is not valid"
        exit 1
    fi 
}

export -f fetch_subdomains extract_subdomains_from_source

function remove_temporary_files() {
    find . -type f -name '*certificate_transparency_subdomain_list*' -exec rm {} +
}

function ctrl_c() {
    remove_temporary_files
    exit 1;
}

trap ctrl_c SIGINT

function show_version() {
cat << 'EOF'
crt v1.0.0 (v1.0.0)
Source available at https://github.com/s3r0s4pi3ns/crt
EOF
}

function show_help() {
    cat <<'EOF'
USAGE:
    crt [OPTIONS] [SOURCE]...

EXAMPLES:
    bash crt.sh "example.com,example2.es"
    cat subdomains.txt | bash crt.sh 
    bash crt.sh -o 'path/to/folder' -t 15 "root.com|root2.es" 

OPTIONS:
    -t                 Select the threads you want to use in the execution
    -o                 Define a file path to save the subdomain text files
    -v                 Display the actual version
    -h                 Print help information
EOF
}

while getopts ":o:t:vh:" arg; do
    case $arg in
        t) THREADS="$OPTARG";;
        o) OUTPUT_PATH="${OPTARG%/}/";;
        v) 
            show_version
            exit 0
        ;;
        h | *)
            show_help
            exit 0
        ;;
    esac
done
shift $(( OPTIND - 1))

# Read from stdin if no arguments provided
if [[ $# -eq 0 ]]; then
    read -t 0.5 -r -d '' DOMAINS
else 
    DOMAINS=$1
    shift
fi 

[[ -z $DOMAINS ]] && echo -e "No domains has been provided to the script" \
    || DOMAINS=$(echo "$DOMAINS" | tr ',|-_/: ' '\n')

if [[ -n $OUTPUT_PATH && $OUTPUT_PATH != './' ]]; then 
    mkdir -p "$OUTPUT_PATH"
    chmod 0755 "$OUTPUT_PATH"
fi 

echo "$DOMAINS" | xargs -I {} -P"$THREADS" bash -c "fetch_subdomains {} $OUTPUT_PATH $CACHE_PATH"
wait
