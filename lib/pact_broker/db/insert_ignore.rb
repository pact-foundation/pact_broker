# This module can be included into a Sequel model to change its default save/create behaviour
# to insert_ignore, to allow instances to be created during race conditions without raising
# errors

# Rather than re-writing the whole save method and all the hooks and validation logic in it,
# it naughtily overrides the private insert methods

module PactBroker
  module DB
    module InsertIgnore

      # def save(opts = {})
      #   if opts[:ignore_duplicate]

      #     # self.model.dataset = self.model.dataset.insert_ignore
      #     self.model.instance_variable_set(:@instance_dataset, self.model.instance_dataset.insert_ignore)
      #     super(opts)
      #   else
      #     super(opts)
      #   end
      # end

      def _insert_dataset
        super.insert_ignore
      end
    end
  end
end
