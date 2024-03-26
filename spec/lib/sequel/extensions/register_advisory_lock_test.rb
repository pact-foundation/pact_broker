require "sequel/extensions/pg_advisory_lock"

describe Sequel::Postgres::PgAdvisoryLock do
  subject { Sequel::Model.db }

  describe "#register_advisory_lock" do
    let(:supported_lock_functions) do
      [
        :pg_advisory_lock,
        :pg_try_advisory_lock,
        :pg_advisory_xact_lock,
        :pg_try_advisory_xact_lock
      ]
    end

    let(:default_lock_function) { :pg_advisory_lock }

    before :all do
      Sequel::Model.db.extension(:pg_advisory_lock)
    end

    before do
      subject.registered_advisory_locks.clear
    end

    it "base check" do
      lock_name = :test_lock

      expect(subject.registered_advisory_locks[lock_name]).to be nil
      subject.register_advisory_lock(lock_name)
      expect(default_lock_function).to eq subject.registered_advisory_locks[lock_name].fetch(:lock_function)
    end

    it "should register locks for all supported PostgreSQL functions" do
      supported_lock_functions.each do |lock_function|
        lock_name = "#{lock_function}_test".to_sym

        expect(subject.registered_advisory_locks[lock_name]).to be nil
        subject.register_advisory_lock(lock_name, lock_function)
        expect(lock_function).to eq subject.registered_advisory_locks[lock_name].fetch(:lock_function)
      end
    end

    it "should prevent specifying not supported PostgreSQL function as lock type" do
      lock_name = :not_supported_lock_function_test
      lock_function = :not_supported_lock_function

      expect { subject.register_advisory_lock(lock_name, lock_function) }.to raise_error(Sequel::Error, /Invalid lock function/)
    end

    it "should prevent registering multiple locks with same name and different functions" do
      lock_name = :multiple_locks_with_same_name_test
      subject.register_advisory_lock(lock_name, supported_lock_functions[0])

      expect { subject.register_advisory_lock(lock_name, supported_lock_functions[1]) }.to raise_error(Sequel::Error, /Lock with name .+ is already registered/)
    end

    it "should allow registering multiple locks with same name and same functions" do
      lock_name = :multiple_locks_with_same_name_test
      subject.register_advisory_lock(lock_name, supported_lock_functions[0])

      expect { subject.register_advisory_lock(lock_name, supported_lock_functions[0]) }.to_not raise_error
    end

    it "registered locks must have different lock keys" do
      quantity = 100
      quantity.times do |index|
        lock_name = "test_lock_#{index}".to_sym
        subject.register_advisory_lock(lock_name)
      end

      expect(quantity).to eq subject.registered_advisory_locks.size
      all_keys = subject.registered_advisory_locks.values.map { |v| v.fetch(:key) }
      expect(all_keys.size).to eq all_keys.uniq.size
    end

    it "mapping between lock name and lock key must be constant" do
      expect(subject.registered_advisory_locks).to be_empty

      lock_names_keys_mapping = YAML.load_file(File.join(File.dirname(__FILE__), "lock_names_keys.yml"))

      lock_names_keys_mapping.each do |lock_name, valid_lock_key|
        lock_name = lock_name.to_sym
        subject.register_advisory_lock(lock_name)
        expect(valid_lock_key).to eq subject.registered_advisory_locks[lock_name].fetch(:key)
      end
    end
  end
end
