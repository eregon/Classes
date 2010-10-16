class Module
  def attr_cached(name, &block)
    ivar = "@cached_#{name}"
    define_method(name) do
      instance_variable_get(ivar) || instance_variable_set(ivar, instance_exec(&block))
    end
  end
end
