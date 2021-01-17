Sequel.migration do
  change do
    add_column(:versions, :branch, String)
    add_column(:versions, :build_url, String)
  end
end
