# frozen_string_literal: true

module AuroraDataApi
  class Depot
    def self.[](model, &block)
      depot = self.new(model, &block)
      AuroraDataApi.const_set("#{model.name}Depot".to_sym, depot)
      depot
    end

    def initialize(model, &block)
      @model = model
      self.instance_eval(&block)
      @data_service = DataService.new
    end

    def table_name
      @table_name ||= Model::SCHEMA[@model.name.to_sym][:table_name] || "#{@model.to_s.downcase}s"
    end

    def insert(obj)
      params = Hash.new.tap do |hash|
        obj.members.each do |member|
          obj.send(member).then{|v| hash[member] = v if v}
        end
      end
      raise ArgumentError, "All attributes are nil" if params.empty?
      res = query(<<~SQL, **params)
        INSERT INTO "#{obj.table_name}"
          (#{params.keys.map{|k|"\"#{k}\""}.join(",")})
          VALUES
          (#{params.keys.map{|k|":#{k}"}.join(",")})
          RETURNING "#{obj.literal_id}";
      SQL
      obj._set_id(res.records[0][0].value)
    end

    def update(obj)
      if true
        true
      else
        false
      end
    end

    def delete(obj)
      query(<<~SQL, id: obj.id)
        DELETE FROM "#{obj.table_name}" WHERE "#{obj.literal_id}" = :id;
      SQL
      obj._destroy
      true
    end

    def select(str, **params)
      result = query("select * from \"#{table_name}\" #{str};", **params)
      related_objects = Hash.new
      result.records.map do |record|
        relationships = Hash.new
        attributes = Hash.new.tap do |attrribute|
          result.column_metadata.each_with_index do |meta, index|
            if meta.table_name == table_name.to_s
              attrribute[meta.name.to_sym] = column_data(meta, record[index])
            else
              table_sym = meta.table_name.to_sym
              name, rel_model = @model.relationship_by(table_sym)
              if name
                relationships[name] ||= Hash.new
                relationships[name][:attr] ||= Hash.new
                relationships[name][:model] ||= rel_model
                relationships[name][:attr][meta.name.to_sym] = column_data(meta, record[index])
              end
            end
          end
        end
        relationships.each do |name, data|
          related_objects[name] ||= Hash.new
          id = data[:attr][Model::SCHEMA[@model.name.to_sym][:literal_id]]
          unless obj = related_objects.dig(name, id)
            obj = Kernel.const_get(data[:model]).new(**data[:attr])
            related_objects[name][id] = obj
          end
          attributes[name] = obj
        end
        @model.new(attributes)
      end
    end

    def column_data(meta, col)
      case meta.type_name
      when "text"
        col.value.gsub("''", "'")
      when "timestamptz"
        Time.parse(col.value) + 9*60*60 # workaround
      else
        col.value
      end
    end

    def query(str, **params)
      @data_service.execute({
        sql: str,
        parameters: params.map do |param|
          hash = { name: param[0].to_s, value: {} }
          case param[1]
          when Integer
            hash[:value][:long_value] = param[1]
          when Float
            hash[:value][:double_value] = param[1]
          when TrueClass, FalseClass
            hash[:value][:boolean_value] = param[1]
          else # TODO: confirm format and timezone when Time
            hash[:value][:string_value] = param[1].to_s.gsub("'", "''")
          end
          hash
        end
      })
    end

  end
end
