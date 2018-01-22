Sequel.migration do
  change do

    # This view includes all the latest pacts, as well as the latest pacts
    # for each tag.
    # If a pact publication is the latest AND the latest tagged version
    # there will be two rows in this view for it - one for the top
    # query,and one for the bottom.
    create_view(:head_pact_publications,
      "select lp.*, null as tag_name, 1 as latest
      from latest_pact_publications lp

      UNION

      select ltp.*, null as latest
      from latest_tagged_pact_publications ltp
      "
    )

  end
end
