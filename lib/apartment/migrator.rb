module Apartment

  module Migrator

    extend self

    # Migrate to latest
    def migrate(database)
      Database.process(database) do
        ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil) do |migration|
          ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
        end
      end
    end

    # Dump schema.rb from specified database
    def dump(database, stream = nil)
      stream ||= File.new("db/schema.rb", "w+")
       Database.process(database) do
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
      end
    ensure
      begin
        stream.close if stream.respond_to?(:close)
      rescue
      end
    end

    # Migrate up/down to a specific version
    def run(direction, database, version)
      Database.process(database){ ActiveRecord::Migrator.run(direction, ActiveRecord::Migrator.migrations_path, version) }
    end

    # rollback latest migration `step` number of times
    def rollback(database, step = 1)
      Database.process(database){ ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_path, step) }
    end
  end

end
