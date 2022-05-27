# frozen_string_literal: true

module AuroraDataApi
  class Repo
    def self.[](model, &block)
      self.new(model, &block)
    end

    def initialize(model, &block)
      @model = model
      self.instance_eval(&block)
      @data_service = DataService.new
    end

    def table_name
      @table_name ||= @model::SCHEMA[@model.name.to_sym][:table_name] || "#{@model.to_s.downcase}s"
    end

    def create(item)
    end

    def update(item)
    end

    def delete(item)
    end

    def select(str, **params)
      result = query("select * from \"#{table_name}\" #{str};", **params)
      related_objects = Hash.new
      result.records.map do |record|
        relations = Hash.new
        attributes = Hash.new.tap do |attrribute|
          result.column_metadata.each_with_index do |meta, index|
            if meta.table_name == table_name.to_s
              attrribute[meta.name.to_sym] = column_data(meta, record[index])
            else
              table_sym = meta.table_name.to_sym
              if @model::RELATIONS[table_sym]
                relations[table_sym] ||= Hash.new
                relations[table_sym][meta.name.to_sym] = column_data(meta, record[index])
              end
            end
          end
        end
        relations.each do |table_sym, att|
          model = @model::RELATIONS[table_sym]
          related_objects[table_sym] ||= Hash.new
          id = relations[table_sym][@model::SCHEMA[@model.name.to_sym][:literal_id]]
          unless obj = related_objects.dig(table_sym, id)
            obj = Kernel.const_get(model[:model]).new(**relations[table_sym])
            related_objects[table_sym][id] = obj
          end
          attributes[model[:relation]] = obj
        end
        @model.new(attributes)
      end
    end

    def column_data(meta, col)
      if meta.type_name == "timestamptz"
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
