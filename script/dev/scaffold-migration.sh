#!/bin/sh

PROJECT_ROOT=$(cd "$(dirname $0)"/../.. && pwd)

today=$(date '+%Y%m%d')

migration_path="${PROJECT_ROOT}/db/migrations/${today}_rename_this.rb"


cat <<EOT > ${migration_path}
Sequel.migration do
  up do

  end

  down do

  end
end
EOT

echo "Created ${migration_path}"
