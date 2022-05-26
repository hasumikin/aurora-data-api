# frozen_string_literal: true

module AuroraDataApi
  class Model
    SCHEMA = Hash.new
    STRUCTS = Hash.new
    RELATIONS = Hash.new

    def self.model_name
      self.to_s.to_sym
    end

    def self.literal_id(lit)
      SCHEMA[model_name] ||= Hash.new
      SCHEMA[model_name][:literal_id] = lit
    end

    def self.table_name(name)
      SCHEMA[model_name] ||= Hash.new
      SCHEMA[model_name][:table_name] = name
    end

    def self.schema(&block)
      block.call
      col :created_at, Time
      col :updated_at, Time
      STRUCTS[model_name] = Struct.new(model_name.to_s, *SCHEMA[model_name].keys)
    end

    def self.col(name, type = String, opt = {})
      SCHEMA[model_name] ||= Hash.new
      if type.is_a? Symbol
        SCHEMA[model_name]["#{name}_#{SCHEMA[model_name][:literal_id] || :id}".to_sym] = { type: Integer, opt: opt }
        RELATIONS[opt[:table_name] || "#{type}s"] = { model: type, relation: name }
      end
      SCHEMA[model_name][name] = { type: type, opt: opt }
    end

    def self.type_of(name)
      type = SCHEMA[model_name][name][:type]
      type.is_a?(Symbol) ? Kernel.const_get(type) : type
    end

    def initialize(**params)
      @struct = STRUCTS[self.class.model_name].new
      params.each do |col, val|
        if col == literal_id
          instance_variable_set("@#{literal_id}", params[literal_id])
        else
          @struct[col] = val
        end
      end
    end

    def members
      [literal_id] + @struct.members
    end

    def method_missing(method_name, *args, &block)
      string_name = method_name.to_s
      if string_name[-1] == "="
        @struct[string_name.chop] = args[0]
      elsif string_name[-3, 3] == "_#{literal_id}"
        @struct[string_name.sub(/_#{literal_id}\z/, '')]&.id || @struct[method_name]
      elsif method_name == SCHEMA[self.class.model_name][:literal_id]
        instance_variable_get("@#{literal_id}")
      else
        @struct[method_name]
      end
    end

    private def literal_id
      SCHEMA[self.class.model_name][:literal_id] || :id
    end
  end
end

