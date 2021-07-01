#!/bin/sh

for file in $(find spec/fixtures/approvals -ipath "*.received.*"); do
  approved_path=$(echo "$file" | sed 's/received/approved/')
  mv "$file" "$approved_path"
done;
