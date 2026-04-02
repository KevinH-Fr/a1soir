# frozen_string_literal: true

module OnlineSales
  def self.available?
    Rails.application.config.x.online_sales_available
  end
end
