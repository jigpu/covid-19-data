#!/bin/sh

# Local county-specific statistics that I care about. Feel free to change
# The filters with your own.

FILE=$(ls us-counties*.csv | tail -n1)
DATE=$(cut -d, -f1 "$FILE" | grep "^20" | sort | tail -n1)

./plot.sh "$FILE" " (Oregon|Washington)$" "Marion|Clark|Multnomah" "OR/WA County Cases Through ${DATE}"
