dataset =
  SDB[:items]
    .left_join(:categories, { id: :category_id })
    .select { Sequel[:items][:name] }

class SComplexDataset < Sequel::Model(dataset)
end
