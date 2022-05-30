# frozen_string_literal: true

module AuroraDataApi
  class Model
    SCHEMA = {}
    STRUCTS = {}

    def self.model_name
      to_s.to_sym
    end

    def self.literal_id(lit)
      SCHEMA[model_name] ||= {}
      SCHEMA[model_name][:literal_id] = lit
    end

    def self.table_name
      SCHEMA.dig(model_name, :table_name)
    end

    def self.table(name)
      SCHEMA[model_name] ||= {}
      SCHEMA[model_name][:table_name] = name
    end

    def self.schema(&block)
      block.call
      STRUCTS[model_name] = Struct.new(model_name.to_s, *SCHEMA[model_name][:cols].keys)
      table("#{name.to_s.downcase}s".to_sym) if table_name.nil?
    end

    def self.col(name, type, opt = {})
      SCHEMA[model_name] ||= {}
      SCHEMA[model_name][:cols] ||= {}
      if type.is_a? Symbol
        SCHEMA[model_name][:cols]["#{name}_#{SCHEMA[model_name][:literal_id] || :id}".to_sym] = {type: Integer}
      end
      SCHEMA[model_name][:cols][name] = {type: type, opt: opt}
    end

    def self.timestamp
      col :created_at, Time, null: false
      col :updated_at, Time, null: false
    end

    def self.relationship_by(table_sym)
      result = Model::SCHEMA[name&.to_sym].select { |_k, v|
        v.is_a? Hash
      }.select { |_k, v|
        v.dig(:opt, :table) == table_sym
      }
      result.count > 0 ? [result.keys[0], result.values[0][:type]] : nil
    end

    def initialize(**params)
      @struct = STRUCTS[self.class.model_name].new
      @timestamp = %i[created_at updated_at].all? { |m| members.include?(m) }
      params.each do |col, val|
        if col == literal_id
          @id = val if val.is_a?(Integer)
        else
          @struct[col] = val
        end
      end
    end

    attr_reader :id, :timestamp

    def set_timestamp(at:)
      return false unless @timestamp
      self.updated_at = Time.now
      self.created_at = Time.now if at == :create
      true
    end

    def members
      [literal_id] + @struct.members
    end

    def respond_to_missing?(symbol, include_private)
      # test-unit calls :encoding in assert_equal
      !(%i[encoding].include? symbol)
    end

    def method_missing(method_name, *args, &block)
      string_name = method_name.to_s
      if string_name[-1] == "="
        @struct[string_name.chop] = args[0]
      elsif string_name[-3, 3] == "_#{literal_id}"
        @struct[string_name.sub(/_#{literal_id}\z/, "")]&.id || @struct[method_name]
      elsif method_name == literal_id
        @id
      elsif members.include?(method_name)
        if @struct[method_name].nil?
          col_id = "#{method_name}_#{literal_id}".to_sym
          if members.include?(col_id) && @struct[col_id]
            col_model = SCHEMA[self.class.name&.to_sym][:cols].dig(method_name, :type)
            return nil unless col_model
            @struct[method_name] = AuroraDataApi.const_get("#{col_model}Depot".to_sym).select(
              %(where "#{literal_id}" = :id), id: @struct[col_id]
            )[0]
          end
        else
          @struct[method_name]
        end
      else
        super
      end
    end

    def table_name
      SCHEMA[self.class.name&.to_sym][:table_name]
    end

    def literal_id
      SCHEMA[self.class.model_name][:literal_id] || :id
    end

    def build_params(include_id: false)
      {}.tap do |hash|
        members.each do |member|
          next if member == literal_id && !include_id
          next if SCHEMA[self.class.name.to_sym][:cols][member][:type].is_a? Symbol
          send(member).then { |v| hash[member] = v }
        end
      end
    end

    def attributes
      {}.tap do |hash|
        members.each do |member|
          next if member.to_s.match?(/_#{literal_id}\z/)
          send(member).then do |v|
            hash[member] = v.is_a?(Model) ? v.attributes : v
          end
        end
      end
    end

    def _set_id(id)
      @id = id
    end

    def _destroy
      @id = nil
      @struct.members.each do |member|
        @struct[member] = nil unless member == literal_id
      end
      true
    end
  end
end
