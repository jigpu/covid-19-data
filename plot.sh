#!/bin/bash

# plot.sh
#
# Usage:


read -r -d '' AWKPROG <<'EOF'
BEGIN {
  FS=",";
  OFS="\t";
  K=7;
  RATIO=1/K;
}

{
  if ($3 ~ FIPS) {
    if (HEADER==0) {
      print $2, "AvgNew";
      HEADER=1;
    }

    PRIOR=TOTAL
    TOTAL=$4
    NEW=TOTAL-PRIOR

    # Use IIR filter
    #IIR=IIR*(1-RATIO)+NEW*RATIO;
    #print TOTAL, IIR;

    # Use FIR filter
    LIST[X] = NEW;
    X = (X + 1) % K;
    FIR=0
    for (i = 0; i < K; i++) { FIR += LIST[i]; }
    print TOTAL, FIR;
  }
}
EOF

if [[ $# -ne 4 && $# -ne 3 ]]; then
  echo "Plot CSV data for COVID-19 cases from The New York Times dataset"
  echo "Produces the same week-averaged log-log 'trajectory' plots as"
  echo "introduced by https://aatishb.com/covidtrends/"
  echo
  echo "Requires GNUplot"
  echo
  echo "Usage: $0 <input> <filter> <highlight> [title]"
  echo
  echo " input      CSV file to process"
  echo " filter     Regex to select states/counties to plot"
  echo " highlight  Regex to select states/counties to highlight"
  echo " title      Title of graph"
  echo 
  echo "Examples:"
  echo
  echo $0 'us-states.csv "" "New York" "COVID-19 Cases in New York"'
  echo $0 'us-states.csv "Washington|Oregon|California" "California" "California COVID-19 Cases vs. West Coast"'
  echo $0 'us-counties.csv "New York" "Nassau New York" "Nassau County, New York COVID-19 Cases"'
  echo
  echo "For regex purposes, county names may be concatenated with their parent state."
  echo "For example, \"Washington Alabama\", \"Washington Arkansas\", etc."
  exit 1
fi

INPUT_FILE=$1
FILTER=$2
HIGHLIGHT=$3
TITLE=$4


if [[ -z "${TITLE}" ]]; then TITLE=$INPUT_FILE; fi


DATA=$(tail -n+2 "$INPUT_FILE" | sort -n)
head -n1 "$1" | grep -q "county" && DATA=$(awk -vFS=, -vOFS=',' '{print $1, $2 " " $3, $4, $5, $6}' <<< "$DATA")
CODES=$(echo "$DATA" | awk -vFS=, -vFILTER="${FILTER}" '{if ($2 ~ FILTER) { print $3 }}' | sort | uniq)
echo "Processing FIPS codes " $CODES

STYLE=2
for FIPS in $CODES; do
  OUTFILE="${FIPS}.dat"
  awk -vFIPS="^${FIPS}\$" "$AWKPROG" <<< "$DATA" > "${OUTFILE}"

  STATE=$(head -n1 "${OUTFILE}" | cut -f1)
  PROG="${PROG} \"${OUTFILE}\" every ::2 with lines"

  if grep -Eq "${HIGHLIGHT}" <<< ${STATE}; then
    PROG="${PROG} title '${STATE}' linestyle ${STYLE} linewidth 3,"
    STYLE=$((${STYLE} + 1))
  else
    PROG="${PROG} linestyle 1 notitle,"
  fi
done

gnuplot -p \
  -e 'set title "'"${TITLE}"'"' \
  -e 'set xlabel "Total cases reported"' \
  -e 'set ylabel "7-Day average of cases reported"' \
  -e 'set logscale xy' \
  -e 'set xrange [1<*:]' \
  -e 'set yrange [1<*:]' \
  -e 'load "gnuplot-palettes/dark2.pal"' \
  -e 'set style line 1 linecolor rgb "#aaaaaaaa" linetype 1 linewidth 1 dashtype 2' \
  -e "plot ${PROG}"


