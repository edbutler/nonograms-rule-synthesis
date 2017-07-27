#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "Usage: $0 <config-file>"
    exit 1
fi

cat $1 | racket src/run-create-training-set.rkt -i || exit 1
cat $1 | racket src/run-create-work-list.rkt -i || exit 1
cat $1 | racket src/run-batch-learn-rules.rkt -i || exit 1
cat $1 | racket src/run-create-test-set.rkt -i || exit 1

