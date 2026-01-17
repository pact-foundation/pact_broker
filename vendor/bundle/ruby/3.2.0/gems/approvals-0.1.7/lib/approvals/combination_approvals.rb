class CombinationApprovals
  def self.verify_all_combinations(*arg_variations, namer:)
    combo = new()
    arg_variations.each do |list|
      combo.arg(list)
    end

    output = ""
    combo.all_combinations.each do |args|
      begin
        result = yield *args
      rescue StandardError => exception
        result = "#{exception.inspect}"
      end
      output << "#{args} => #{result}\n"
    end
    Approvals.verify(output, namer: namer)
  end

  def arg(values)
    @args ||= []
    @args << values
  end

  def all_combinations()
    first, *rest = *@args
    first.product(*rest)
  end
end
