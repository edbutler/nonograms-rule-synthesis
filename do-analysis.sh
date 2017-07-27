#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "Usage: $0 <config-file>"
    exit 1
fi

cat $1 | racket src/run-analyze-results.rkt -i || exit 1
cat $1 | racket src/run-visualize-analysis-results.rkt html/results.html -i || exit 1
racket src/run-visualize-builtins.rkt html/builtins.html || exit 1

