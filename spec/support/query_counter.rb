module QueryCounter
  # Returns the number of SELECT statements run against the database while the block executes.
  #
  # PactPublication's forbid_lazy_load guard is lifted for the duration, so the count reflects
  # what a production request issues instead of raising on the first lazy load.
  def count_select_queries
    Thread.current[:query_counter_count] = 0
    yield
    Thread.current[:query_counter_count]
  ensure
    Thread.current[:query_counter_count] = nil
  end

  def self.counting?
    !Thread.current[:query_counter_count].nil?
  end

  module CountSelects
    def log_connection_yield(sql, conn, args = nil, &block)
      if QueryCounter.counting? && sql.to_s.upcase.start_with?("SELECT") && !sql.to_s.include?("sqlite_master")
        Thread.current[:query_counter_count] += 1
      end
      super
    end
  end

  module AllowLazyLoad
    private

    def _load_associated_objects(opts, *args, &block)
      allow_lazy_load if QueryCounter.counting?
      super
    end
  end
end

PactBroker::DB.connection.singleton_class.prepend(QueryCounter::CountSelects)
PactBroker::Pacts::PactPublication.prepend(QueryCounter::AllowLazyLoad)

RSpec.configure do |config|
  config.include QueryCounter
end
