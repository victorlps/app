#!/bin/bash
cd "$(dirname "$0")/avisa_la" && flutter build apk "$@" && flutter install -d RQCW307SRFT
