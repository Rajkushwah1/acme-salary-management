module Api
  module V1
    class MetaController < ApplicationController
      # GET /api/v1/meta
      # Dropdown reference values for filters and creation forms
      def index
        countries = Country.order(:name).select(:id, :name, :code, :default_currency)
        departments = Department.order(:name).select(:id, :name, :code)

        render json: {
          countries: countries,
          departments: departments,
          pay_frequencies: SalaryRecord::PAY_FREQUENCIES,
          currencies: %w[USD EUR GBP INR JPY CAD AUD CHF]
        }
      end
    end
  end
end
