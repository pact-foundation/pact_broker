Sequel.migration do
  change do
    add_column(:versions, :order, Integer)
    self[:versions].update(:order => :id)
  end
end

