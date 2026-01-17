module Expgen
  module Randomizer
    extend self

    def range(min, max)
      if min == "*"
        [0,5]
      elsif min == "+"
        [1,5]
      elsif min and max
        [min, max]
      elsif min
        [min, min]
      else
        [1,1]
      end
    end

    def repeat(min, max)
      first, last = range(min, max)
      number = rand(last - first + 1) + first
      number.times.map { yield }.join
    end

    def randomize(tree)
      case tree
        when Array              then tree.map { |el| randomize(el) }.join
        when Nodes::Alternation then randomize(tree.options.sample)
        when Nodes::Group       then repeat(tree.repeat, tree.max) { randomize(tree.elements) }
        when Nodes::Character   then repeat(tree.repeat, tree.max) { tree.chars.sample }
      end
    end
  end
end
