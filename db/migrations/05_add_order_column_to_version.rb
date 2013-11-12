Sequel.migration do
  change do
    add_column(:versions, :order, Integer)
  end
end

