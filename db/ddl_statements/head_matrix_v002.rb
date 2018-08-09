HEAD_MATRIX_V2 = "
select
  p.consumer_id, p.consumer_name, p.consumer_version_id, p.consumer_version_number, p.consumer_version_order,
  p.id as pact_publication_id, p.pact_version_id, p.pact_version_sha, p.revision_number as pact_revision_number,
  p.created_at as pact_created_at,
  p.provider_id, p.provider_name, lv.provider_version_id, lv.provider_version_number, lv.provider_version_order,
  lv.id as verification_id, lv.success, lv.number as verification_number, lv.execution_date as verification_executed_at,
  lv.build_url as verification_build_url,
  null as consumer_version_tag_name
from latest_pact_publications p
left outer join latest_verifications_for_pact_versions lv
  on p.pact_version_id = lv.pact_version_id

union all

select
  p.consumer_id, p.consumer_name, p.consumer_version_id, p.consumer_version_number, p.consumer_version_order,
  p.id as pact_publication_id, p.pact_version_id, p.pact_version_sha, p.revision_number as pact_revision_number,
  p.created_at as pact_created_at,
  p.provider_id, p.provider_name, lv.provider_version_id, lv.provider_version_number, lv.provider_version_order,
  lv.id as verification_id, lv.success, lv.number as verification_number, lv.execution_date as verification_executed_at,
  lv.build_url as verification_build_url,
  lt.tag_name as consumer_version_tag_name
from latest_tagged_pact_consumer_version_orders lt
inner join latest_pact_publications_by_consumer_versions p
  on lt.consumer_id = p.consumer_id
  and lt.provider_id = p.provider_id
  and lt.latest_consumer_version_order = p.consumer_version_order
left outer join latest_verifications_for_pact_versions lv
  on p.pact_version_id = lv.pact_version_id
"
