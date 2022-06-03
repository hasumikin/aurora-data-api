require "date"

module AuroraDataApi
  class Converter
    TYPES = {
      ::Date => "date",
      ::Time => "timestamp with time zone",
      ::String => "text",
      ::Integer => "bigint",
      ::Float => "double precision",
      ::AuroraDataApi::Type::Boolean => "boolean"
    }

    def initialize(schema, klass)
      @table_name = schema[:table_name] || "#{klass.name.downcase}s"
      @literal_id = schema[:literal_id]
      @create_table = []
      @alter_table = []
    end

    attr_reader :create_table, :alter_table

    def head
      @create_table << %/CREATE TABLE "#{@table_name}" (/
      @create_table << %(  "#{@literal_id}" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,)
    end

    def tail
      @create_table << %/  PRIMARY KEY ("#{@literal_id}")/
      @create_table << %/);\n/
    end

    def timestamp
      @create_table << %(  "created_at" #{TYPES[Time]} NOT NULL,)
      @create_table << %(  "updated_at" #{TYPES[Time]} NOT NULL,)
    end

    def col(name, type, **params)
      line = "  "
      case type
      when Symbol
        col_name = "#{name}_#{@literal_id}"
        line << %("#{col_name}" )
        line << TYPES[Integer]
        @alter_table << %/ALTER TABLE ONLY "#{@table_name}" ADD CONSTRAINT "#{@table_name}_#{col_name}_fkey" FOREIGN KEY ("#{col_name}") REFERENCES "#{params[:table]}" ("#{@literal_id}");/
      else
        line << %("#{name}" )
        line << TYPES[type]
      end
      params.each do |k, v|
        case k
        when :null
          line << " NOT NULL" unless v
        when :default
          line << " DEFAULT "
          line << case v
          when String, Symbol
            "'#{v}'"
          else
            v.to_s
          end
        when :unique
          line << " UNIQUE" if v
        end
      end
      line << ","
      @create_table << line
    end
  end
end
