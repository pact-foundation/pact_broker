#!/bin/sh

git ls-files -m | xargs ls -1 2>/dev/null | grep -e '\.rb$' -e '\.rake$' | xargs rubocop --except Style/StringLiterals
