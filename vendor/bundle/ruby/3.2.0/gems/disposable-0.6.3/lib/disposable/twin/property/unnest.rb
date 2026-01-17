module Disposable::Twin::Property
  module Unnest
    # TODO: test that nested properties options are "unnested", too, e.g. populator.

    def unnest(name, options)
      from = options.delete(:from)
      # needed to make reform process this field.

      options = definitions.get(from)[:nested].definitions.get(name).instance_variable_get(:@options) # FIXME.
      options = options.merge(virtual: true, _inherited: true, private_name: nil)

      property(name, options)
      # def_delegators from, name, "#{name}=" # FIXME: this overwrites ActiveSupport#delegate in some cases.

      define_method name do
        send(from).send(name) # TODO: fix Forwardable in Ruby.
      end

      define_method "#{name}=" do |value|
        send(from).send("#{name}=", value)
      end
    end
  end
end
