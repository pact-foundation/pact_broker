Sequel.migration do
  up do
    create_view(:head_pact_tags, head_pact_tags_v1(self))
  end

  down do
    drop_view(:head_pact_tags)
  end
end
