# frozen_string_literal: true

# PostgreSQL plie les accents dans le SQL. SQLite appelle AccentFold.fold.
ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.set_callback(:checkout, :after) do
    raw = raw_connection
    next if raw.instance_variable_defined?(:@accent_fold)

    raw.create_function("accent_fold", 1) do |func, value|
      func.result = AccentFold.fold(value.to_s)
    end
    raw.instance_variable_set(:@accent_fold, true)
  end
end
