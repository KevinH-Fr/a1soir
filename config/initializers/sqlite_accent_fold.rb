# frozen_string_literal: true

# PostgreSQL plie les accents dans le SQL. SQLite appelle AccentFold.fold.
# La gem sqlite3 n'est pas dans le bundle de production : ne pas charger l'adaptateur.
ActiveSupport.on_load(:active_record) do
  next if Gem::Specification.find_all_by_name("sqlite3").empty?

  require "active_record/connection_adapters/sqlite3_adapter"

  ActiveRecord::ConnectionAdapters::SQLite3Adapter.set_callback(:checkout, :after) do
    raw = raw_connection
    next if raw.instance_variable_defined?(:@accent_fold)

    raw.create_function("accent_fold", 1) do |func, value|
      func.result = AccentFold.fold(value.to_s)
    end
    raw.instance_variable_set(:@accent_fold, true)
  end
end
