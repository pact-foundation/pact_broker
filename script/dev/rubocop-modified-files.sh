#!/bin/sh

git ls-files -m | xargs ls -1 2>/dev/null | grep -e '\.rb$' -e '\.ru$' -e '\.rake$' | xargs rubocop --except Style/StringLiterals
