![crt_thumbnail](/assets/ssl_mirror.jpg)

# crt

Abusing Certificate Transparency logs for getting subdomains from a root domain. The process is very clean, a light http request to [crt.sh](https://crt.sh) to fetch the subdomain information in a manipulatable format supporting multiple root domains at once.

## Usage

- The default output path is the current directory, so when the information is fetched it creates for each domain a `subdomains_<domain>.txt` file in this path
- **Important:** The domains must be the last argument in the script execution if does not comes from stdin

```bash
# Unexpected behavior
bash crt.sh "example.com example.es" -o 'output/folder' -t 5

# Works
bash crt.sh -o 'output/folder' -t 5 "example.com example.es"
cat subdomains.txt | bash crt.sh -o 'output/folder' -t 5
```

```bash
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
```

## Examples

### Simple enumeration from file

```bash
cat subdomains.txt | bash crt.sh

[-] Fetching certificate transparency history for domain example.com ...
[-] Fetching certificate transparency history for domain example3.com ...
[-] Fetching certificate transparency history for domain example2.com ...
[-] Fetching certificate transparency history for domain example4.com ...
```

### Enumeration from raw text

```bash
# Supported delimiters , - _ | / : ' '
bash crt.sh "example.com,example.es,example.org"

bash crt.sh "example.com|example.es|example.org"

bash crt.sh "example.com:example.es:example.org"

bash crt.sh "example.com/example.es/example.org"

bash crt.sh "example.com-example.es-example.org"

bash crt.sh "example.com_example.es_example.org"

bash crt.sh "example.com example.es example.org"
```

### Select the output of subdomain .txt files

```bash
cat subdomains.txt | bash crt.sh -o 'my/output/folder'

# my/output/folder/subdomains_example.com.txt
# my/output/folder/subdomains_example.es.txt
...
```

### Number of threads

```bash
bash crt.sh -t 20 "example.com,example.es,example.org"
```
