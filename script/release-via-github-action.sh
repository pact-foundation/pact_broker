#!/bin/sh
set +e

git tag -d release
git push --delete origin release
git tag -a release -m "chore: releasing"
git push origin release
