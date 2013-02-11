module Migrator
  mattr_accessor :offer_migration_when_available
  @@offer_migration_when_available = true

  def self.migrations_path
    "#{::Rails.root.to_s}/db/migrate"
  end

  def self.available_migrations
    Dir["#{migrations_path}/[0-9]*_*.rb"].sort
  end

  def self.needed_migrations(from)
    migs = []
    available_migrations.each do |mig|
      next if mig.gsub(migrations_path,"").split('_').first.tr('^0-9','').to_i <= from
      migs.push(mig)
    end
    migs
  end

  def self.current_schema_version
    ActiveRecord::Migrator.current_version rescue 0
  end

  def self.max_schema_version
    available_migrations.last.gsub(migrations_path,"").split('_').first.tr('^0-9','').to_i
  end

  def self.db_supports_migrations?
    ActiveRecord::Base.connection.supports_migrations?
  end

  def self.migrate(version = nil)
    ActiveRecord::Migrator.migrate("#{migrations_path}/", version)
  end
end
