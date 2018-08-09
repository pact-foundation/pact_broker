Sequel.migration do
  up do
    create_or_replace_view(:head_matrix, HEAD_MATRIX_V2)
    #TODO
    #drop_view(:latest_verifications)
  end

  down do
    create_or_replace_view(:head_matrix, HEAD_MATRIX_V1)
  end
end
