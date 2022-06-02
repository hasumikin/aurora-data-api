# frozen_string_literal: true

require "date"
require "tzinfo"

module AuroraDataApi
  class Depot
    def self.[](model, &block)
      # @type var block: Proc
      depot = new(model, block)
      AuroraDataApi.const_set("#{model.name}Depot".to_sym, depot)
      depot
    end

    def initialize(model, block)
      @model = model
      instance_eval { block.call }
      @data_service = DataService.new
      @observed_utc_offset = TZInfo::Timezone.get(ENV['TZ'] || "UTC").observed_utc_offset
    end

    def table_name
      @table_name ||= Model::SCHEMA[@model.name.to_sym][:table_name] || "#{@model.to_s.downcase}s"
    end

    def literal_id
      @literal_id ||= Model::SCHEMA[@model.name.to_sym][:literal_id] || :id
    end

    def insert(obj)
      obj.set_timestamp(at: :create)
      params = obj.build_params
      res = query(<<~SQL, **params)
        INSERT INTO "#{obj.table_name}"
          (#{params.keys.map { |k| "\"#{k}\"" }.join(",")})
          VALUES
          (#{params.keys.map { |k| ":#{k}" }.join(",")})
          RETURNING "#{obj.literal_id}";
      SQL
      obj._set_id(res.records[0][0].value)
    end

    def update(obj)
      obj.set_timestamp(at: :update)
      params = obj.build_params
      query(<<~SQL, **params)
        UPDATE "#{obj.table_name}" SET
          #{params.keys.reject { |k| k == obj.literal_id }.map { |k| "\"#{k}\" = :#{k}" }.join(", ")}
          WHERE "#{obj.literal_id}" = :#{obj.literal_id};
      SQL
      true
    end

    def delete(obj)
      query(<<~SQL, id: obj.id)
        DELETE FROM "#{obj.table_name}" WHERE "#{obj.literal_id}" = :id;
      SQL
      obj._destroy
      true
    end

    def count(str = "", **params)
      query(
        "SELECT COUNT(\"#{literal_id}\") FROM \"#{table_name}\" #{str};",
        **params
      ).records[0][0].long_value
    end

    def select(str, **params)
      result = query("select * from \"#{table_name}\" #{str};", **params)
      related_objects = {}
      result.records.map do |record|
        relationships = {}
        attributes = {}.tap do |attrribute|
          result.column_metadata.each_with_index do |meta, index|
            if meta.table_name == table_name.to_s
              attrribute[meta.name.to_sym] = column_data(meta, record[index])
            else
              table_sym = meta.table_name.to_sym
              name, rel_model = @model.relationship_by(table_sym)
              if name
                relationships[name] ||= {}
                relationships[name][:attr] ||= {}
                relationships[name][:model] ||= rel_model
                relationships[name][:attr][meta.name.to_sym] = column_data(meta, record[index])
              end
            end
          end
        end
        relationships.each do |name, data|
          related_objects[name] ||= {}
          id = data[:attr][literal_id]
          obj = related_objects.dig(name, id)
          unless obj
            obj = Kernel.const_get(data[:model]).new(**data[:attr])
            related_objects[name][id] = obj
          end
          attributes[name] = obj
        end
        @model.new(attributes)
      end
    end

    def column_data(meta, col)
      return nil if col.is_null
      case meta.type_name
      when "text"
        col.value.gsub("''", "'")
      when "timestamptz"
        Time.parse(col.value) + @observed_utc_offset
      when "date"
        Date.parse(col.value)
      else
        col.value
      end
    end

    def query(str, **params)
      @data_service.execute({
        sql: str,
        parameters: params.map do |param|
          hash = {name: param[0].to_s, value: {}}
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
