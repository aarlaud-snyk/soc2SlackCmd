#! /bin/bash

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters. we need OWNER and EMAIL. use quotes.."
    echo "for example: $0 \"Danny Grander\" \"danny@snyk.io\""
    exit 1
fi

OWNER="$(echo "$1" | tr "[:lower:]" "[:upper:]")"
EMAIL="$(echo "$2" | tr "[:lower:]" "[:upper:]")"

# create the watermark pdf file
## create the watermark.tex file
cat > watermark.tex << EOF
\documentclass{article}
\usepackage{graphicx}
\usepackage{anyfontsize}
\usepackage[margin=0.25in]{geometry}
\usepackage[usenames, dvipsnames]{color}
\usepackage{transparent}

\begin{document}

\begin{center}
  \vspace*{\fill}
  \color{Gray}
  \transparent{0.3}%  % NOTE: need to run pdflatex twice to get transparency right
  % if the owner name and email are too long (2 pages created, reduce "45" in \fontsize)
  \rotatebox{303}{\fontsize{45}{0}\selectfont \texttt{OWNER-NAME-DASH-EMAIL}}
  \vspace*{\fill}
\end{center}

\end{document}
EOF

# insert owner name into template
sed -i "s/OWNER-NAME-DASH-EMAIL/$OWNER - $EMAIL/" watermark.tex

# create the watermark pdf file
pdflatex watermark.tex  && pdflatex watermark.tex # twice for transparency to work

# watermark the report
OUTFILE="$(echo -n "Snyk-SOC2-$OWNER.pdf" | tr "[:space:]" _)"
TEMP_OUTFILE="$OUTFILE.TEMP"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
pdftk "$DIR/IN.pdf" multistamp watermark.pdf output "$TEMP_OUTFILE"

# add metadata to pdf
pdftk "$TEMP_OUTFILE" dump_data output metadata.info
cat >> metadata.info << EOF
InfoBegin
InfoKey: OWNER
InfoValue: SNYK_SOC2_OWNER
InfoBegin
InfoKey: OWNER-EMAIL
InfoValue: SNYK_SOC2_EMAIL
EOF

sed -i "s/SNYK_SOC2_OWNER/$OWNER/" metadata.info
sed -i "s/SNYK_SOC2_EMAIL/$EMAIL/" metadata.info
sed -i "s/D:20180701170409/D:$(date +%Y%m%d%H%M%S)/" metadata.info  # see drop_xmp in pdftk

PASS="$(tr -cd '[:alnum:]' < /dev/urandom | head -c20)"

# "never" give owner permission (200 char password), no printing
pdftk "$TEMP_OUTFILE" update_info metadata.info output "$OUTFILE" owner_pw "$(tr -cd '[:alnum:]' < /dev/urandom | head -c200)" user_pw "$PASS"

# cleanup
rm -f metadata.info "$TEMP_OUTFILE"
find . -name "watermark.*" ! -name watermark.bash -delete

echo "created $OUTFILE successfully, password is $PASS"

echo "$PASS" > $OUTFILE.password
