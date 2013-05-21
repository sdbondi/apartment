apartment_namespace = namespace :apartment do

  def task_with_database(task, database = nil)
    database ||= Apartment.default_schema

    Apartment.process database do
      Rake::Task[task].invoke
    end
  end

  desc "Dump a database using the 'db' environment variable (or default_schema in config)"
  task 'schema:dump' => :environment do
    ENV['db'] ||= Apartment.default_schema
    task_with_database 'db:schema:dump', ENV['db']
  end

  desc "Migrate all multi-tenant databases"
  task :migrate => :environment do

    Apartment.database_names.each do |db|
      puts("Migrating #{db} database")
      Apartment::Migrator.migrate db
    end

    task_with_database 'db:migrate'
  end

  desc "Seed all multi-tenant databases"
  task :seed => :environment do

    Apartment.database_names.each do |db|
      puts("Seeding #{db} database")
      Apartment::Database.process(db) do
        Apartment::Database.seed
      end
    end

    task_with_database 'db:seed'
  end

  desc "Rolls the schema back to the previous version (specify steps w/ STEP=n) across all multi-tenant dbs."
  task :rollback => :environment do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    Apartment.database_names.each do |db|
      puts("Rolling back #{db} database")
      Apartment::Migrator.rollback db, step
    end
    
    task_with_database 'db:rollback'
  end

  namespace :migrate do

    desc 'Runs the "up" for a given migration VERSION across all multi-tenant dbs.'
    task :up => :environment do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version

      Apartment.database_names.each do |db|
        puts("Migrating #{db} database up")
        Apartment::Migrator.run :up, db, version
      end
      
      task_with_database 'db:migrate:up'
    end

    desc 'Runs the "down" for a given migration VERSION across all multi-tenant dbs.'
    task :down => :environment do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version

      Apartment.database_names.each do |db|
        puts("Migrating #{db} database down")
        Apartment::Migrator.run :down, db, version
      end
    
      task_with_database 'db:migrate:down'
    end    

    desc  'Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
    task :redo => :environment do
      if ENV['VERSION']
        apartment_namespace['migrate:down'].invoke
        apartment_namespace['migrate:up'].invoke
      else
        apartment_namespace['rollback'].invoke
        apartment_namespace['migrate'].invoke
      end
    end

  end

end