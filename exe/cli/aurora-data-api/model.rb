module AuroraDataApi
  class Model
    SCHEMA = {literal_id: :id}

    def self.literal_id(lit)
      SCHEMA[:literal_id] = lit
    end

    def self.table(name)
      SCHEMA[:table_name] = name
    end

    def self.schema(&block)
      converter = Converter.new(SCHEMA, self)
      converter.head
      converter.instance_eval(&block)
      converter.tail
      Schema::CREATE_TABLE << converter.create_table
      Schema::ALTER_TABLE << converter.alter_table
    end
  end
end
