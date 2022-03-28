#!/bin/bash

ARGPARSE_DESCRIPTION="Request LetsEncrypt certificate."
source $(dirname $0)/argparse || exit 1
argparse "$@" <<EOF || exit 1
parser.add_argument("domain",type=str)
parser.add_argument("--dry-run", action='store_true')
EOF

source $(dirname $0)/functions.bash || exit 1

request_ssl_for_domain $DOMAIN

