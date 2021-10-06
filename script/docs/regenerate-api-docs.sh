#!/bin/sh
rm spec/fixtures/approvals/docs_webhooks*
bundle exec rspec spec/integration/webhooks_documentation_spec.rb
script/test/approval-all.sh
bundle exec rspec spec/integration/webhooks_documentation_spec.rb
script/docs/generate-api-docs.rb

git add spec/integration/webhooks_documentation_spec.rb
git add spec/fixtures/approvals
git add docs/api
git add script/docs/generate-api-docs.rb
