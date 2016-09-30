module Validator
  def validators
    @validators ||= []
  end

  def validate(fn_sym)
    validators << [fn_sym]
    setup_instance_validators

  end

  def validates(sym, opts)
    validators << [:validates_fn, sym, opts]
    setup_instance_validators
  end

  def setup_instance_validators
    define_method(:errors) do
      @errors ||= Hash.new {|h,k| h[k] = Array.new}
    end

    define_method(:clear_errors) do
      @errors = Hash.new {|h,k| h[k] = Array.new}
    end

    define_method(:valid?) do
      clear_errors
      self.class.validators.all? do |validator|
        send(*validator)
      end
      errors.empty?
    end

    define_method(:validates_fn) do |sym, opts|
      val = self.send(sym)
      symbol_errors = []
      opts.each do |k, v|
        symbol_errors << "#{k} must be #{v}" if val.send(k) != v
      end
      return true if symbol_errors.empty?
      errors[sym].concat(symbol_errors)
      false
    end
  end
end

class SQLObject
  extend Validator
end
