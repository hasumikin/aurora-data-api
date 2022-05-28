# frozen_string_literal: true

module AuroraDataApi
  class Model
    SCHEMA = Hash.new
    STRUCTS = Hash.new

    def self.model_name
      self.to_s.to_sym
    end

    def self.literal_id(lit)
      SCHEMA[model_name] ||= Hash.new
      SCHEMA[model_name][:literal_id] = lit
    end

    def self.table(name)
      SCHEMA[model_name] ||= Hash.new
      SCHEMA[model_name][:table_name] = name
    end

    def self.schema(&block)
      block.call
      col :created_at, Time
      col :updated_at, Time
      STRUCTS[model_name] = Struct.new(model_name.to_s, *SCHEMA[model_name][:cols].keys)
    end

    def self.col(name, type = String, opt = {})
      SCHEMA[model_name] ||= Hash.new
      SCHEMA[model_name][:cols] ||= Hash.new
      if type.is_a? Symbol
        SCHEMA[model_name][:cols]["#{name}_#{SCHEMA[model_name][:literal_id] || :id}".to_sym] = { type: Integer }
      end
      SCHEMA[model_name][:cols][name] = { type: type, opt: opt }
    end

    def self.type_of(name)
      type = SCHEMA[model_name][name][:type]
      type.is_a?(Symbol) ? Kernel.const_get(type) : type
    end

    def self.relationship_by(table_sym)
      result = Model::SCHEMA[self.name.to_sym].select { |_k, v|
        v.is_a? Hash
      }.select { |_k, v|
        v.dig(:opt, :table) == table_sym
      }
      result.count > 0 ? [result.keys[0], result.values[0][:type]] : nil
    end

    def initialize(**params)
      @struct = STRUCTS[self.class.model_name].new
      params.each do |col, val|
        if col == literal_id
          @id = params[literal_id]
        else
          @struct[col] = val
        end
      end
    end

    attr_reader :id

    def members
      [literal_id] + @struct.members
    end

    def method_missing(method_name, *args, &block)
      string_name = method_name.to_s
      if string_name[-1] == "="
        @struct[string_name.chop] = args[0]
      elsif string_name[-3, 3] == "_#{literal_id}"
        @struct[string_name.sub(/_#{literal_id}\z/, '')]&.id || @struct[method_name]
      elsif method_name == literal_id
        @id
      else
        if members.include?(method_name)
          if @struct[method_name].nil?
            col_id = "#{method_name}_#{literal_id}".to_sym
            if members.include?(col_id) && @struct[col_id]
              col_model = SCHEMA[self.class.name.to_sym][:cols].dig(method_name, :type)
              return nil unless col_model
              @struct[method_name] = AuroraDataApi.const_get("#{col_model.to_s}Depot".to_sym).select(
                %Q/where "#{literal_id}" = :id/, id: @struct[col_id]
              )[0]
            else
              nil
            end
          else
            @struct[method_name]
          end
        else
          super
        end
      end
    end

    def table_name
      SCHEMA[self.class.name.to_sym][:table_name]
    end

    def literal_id
      SCHEMA[self.class.model_name][:literal_id] || :id
    end

    def _set_id(id)
      @id = id
    end

    def _destroy
      @id = nil
      @struct.members.each do |member|
        next if member == literal_id
        @struct[member] = nil
      end
      true
    end
  end
end
