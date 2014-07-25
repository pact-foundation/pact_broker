Sequel.migration do
  up do
    self[:pacts].update(:created_at => DateTime.now, :updated_at => DateTime.now)
    self[:versions].update(:created_at => DateTime.now, :updated_at => DateTime.now)
    self[:pacticipants].update(:created_at => DateTime.now, :updated_at => DateTime.now)
    self[:tags].update(:created_at => DateTime.now, :updated_at => DateTime.now)
  end

  down do
    self[:pacts].update(:created_at => nil, :updated_at => nil)
    self[:versions].update(:created_at => nil, :updated_at => nil)
    self[:pacticipants].update(:created_at => nil, :updated_at => nil)
    self[:tags].update(:created_at => nil, :updated_at => nil)
  end
end
