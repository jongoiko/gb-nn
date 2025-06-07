#!/bin/bash
set -e

if [[ ! -d pretty6502 ]]; then
    git clone https://github.com/nanochess/pretty6502.git
    cd pretty6502
    make
    cd ..
fi

for file in "$@"; do
    TMPFILE=$(mktemp --tmpdir=/tmp/)

    ./pretty6502/pretty6502 $file $TMPFILE
    sed -i 's/\x0//g' $TMPFILE

    mv $TMPFILE $file
done
