Sequel.migration do
  up do
    from(:materialized_matrix).delete
    from(:materialized_matrix).insert(from(:matrix).select_all)
    from(:materialized_head_matrix).delete
    from(:materialized_head_matrix).insert(from(:head_matrix).select_all)
  end

  down do

  end
end
