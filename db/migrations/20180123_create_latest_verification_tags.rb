Sequel.migration do
  change do
    # the provider version order of the latest verification for each consumer/provider/tag
    create_view(:latest_tagged_verification_provider_version_orders,
      "
        select m.consumer_id, m.provider_id, t.name as tag_name, max(m.provider_version_order) as latest_provider_version_order
        from latest_matrix m
        inner join tags t
        on m.provider_version_id = t.version_id
        where m.provider_version_order is not null
        group by m.consumer_id, m.provider_id, t.name
      "
    )

=begin
  The tags for which the given verification is the latest of that tag
  Imagine that:

  provider v1 has verification
              has tag dev
              has tag prod <- latest
  provider v2 has verification
              has tag dev <-latest
  provider v3 has tag dev

  This table would contain the prod tag row for the v1 verification
  This table would contain the dev tag row for the v2 verification
=end
    create_view(:latest_verification_tags,
      "
        select t.*, m.verification_id
        from latest_matrix m
        inner join latest_tagged_verification_provider_version_orders l
        on m.consumer_id = l.consumer_id
        and m.provider_id = l.provider_id
        and m.provider_version_order = l.latest_provider_version_order
        inner join tags t
        on l.tag_name = t.name
        and m.provider_version_id = t.version_id
      "
    )
  end
end