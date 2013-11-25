module AutoWebDocSync


module Util
  def symbolize_keys(value)
    case value
    when Hash
      value.inject({}){|result, (key, value)|
        new_key = case key
                  when String then key.to_sym
                  else key
                  end
        new_value = symbolize_keys(value)
        result[new_key] = new_value
        result
      }
    when Array
      value.collect {|e| symbolize_keys(e)}
    else
      value
    end
  end
end


end
