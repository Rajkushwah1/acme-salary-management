module Api
  module V1
    class AnalyticsController < ApplicationController
      # GET /api/v1/analytics/summary
      # High-level metrics: total employees, active count, currencies
      def summary
        total_employees = Employee.count
        active_employees = Employee.active.count
        inactive_employees = Employee.inactive.count

        # Distinct currencies in active salaries
        currencies = SalaryRecord.joins(:employee)
                                 .where(employees: { status: "active" })
                                 .where("salary_records.effective_from <= :now AND (salary_records.effective_to IS NULL OR salary_records.effective_to > :now)", now: Date.current)
                                 .distinct
                                 .pluck(:currency)
                                 .sort

        render json: {
          total_employees: total_employees,
          active_employees: active_employees,
          inactive_employees: inactive_employees,
          available_currencies: currencies
        }
      end

      # GET /api/v1/analytics/breakdown?currency=USD
      # Rollups per department, country, and designation for a given currency
      # Uses SQL aggregations with annualized compensation: monthly * 12 vs annual
      def breakdown
        currency = params[:currency].presence || "USD"

        base_query = SalaryRecord.joins(:employee)
                                 .where(employees: { status: "active" })
                                 .where(currency: currency)
                                 .where("salary_records.effective_from <= :now AND (salary_records.effective_to IS NULL OR salary_records.effective_to > :now)", now: Date.current)

        annualized_sql = "CASE WHEN salary_records.pay_frequency = 'monthly' THEN salary_records.base_salary * 12 ELSE salary_records.base_salary END"

        # Overall currency summary
        overall = base_query.select(
          "COUNT(*) as employee_count",
          "ROUND(AVG(#{annualized_sql}), 2) as avg_annualized",
          "MIN(#{annualized_sql}) as min_annualized",
          "MAX(#{annualized_sql}) as max_annualized",
          "ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY #{annualized_sql})::numeric, 2) as median_annualized"
        ).take

        # Department-wise breakdown
        by_department = base_query.joins("JOIN departments ON departments.id = employees.department_id")
                                  .group("departments.id, departments.name")
                                  .select(
                                    "departments.id as department_id",
                                    "departments.name as department_name",
                                    "COUNT(employees.id) as employee_count",
                                    "ROUND(AVG(#{annualized_sql}), 2) as avg_annualized",
                                    "MIN(#{annualized_sql}) as min_annualized",
                                    "MAX(#{annualized_sql}) as max_annualized"
                                  ).order("avg_annualized DESC")

        # Country-wise breakdown
        by_country = base_query.joins("JOIN countries ON countries.id = employees.country_id")
                               .group("countries.id, countries.name, countries.code")
                               .select(
                                 "countries.id as country_id",
                                 "countries.name as country_name",
                                 "countries.code as country_code",
                                 "COUNT(employees.id) as employee_count",
                                 "ROUND(AVG(#{annualized_sql}), 2) as avg_annualized",
                                 "MIN(#{annualized_sql}) as min_annualized",
                                 "MAX(#{annualized_sql}) as max_annualized"
                               ).order("employee_count DESC")

        # Salary distribution buckets
        min_val = overall&.min_annualized&.to_f || 0
        max_val = overall&.max_annualized&.to_f || 0
        buckets = []

        if min_val > 0 && max_val > min_val
          step = ((max_val - min_val) / 5.0).ceil
          5.times do |i|
            b_start = min_val + (i * step)
            b_end = b_start + step
            count = base_query.where("#{annualized_sql} >= :s AND #{annualized_sql} < :e", s: b_start, e: (i == 4 ? b_end + 1 : b_end)).count
            buckets << {
              label: "#{b_start.to_i.to_fs(:delimited)} - #{b_end.to_i.to_fs(:delimited)}",
              min: b_start,
              max: b_end,
              count: count
            }
          end
        end

        render json: {
          currency: currency,
          overall: {
            employee_count: overall&.employee_count.to_i,
            avg_annualized: overall&.avg_annualized&.to_f || 0,
            median_annualized: overall&.median_annualized&.to_f || 0,
            min_annualized: overall&.min_annualized&.to_f || 0,
            max_annualized: overall&.max_annualized&.to_f || 0
          },
          by_department: by_department.map do |d|
            {
              id: d.department_id,
              name: d.department_name,
              employee_count: d.employee_count.to_i,
              avg_annualized: d.avg_annualized.to_f,
              min_annualized: d.min_annualized.to_f,
              max_annualized: d.max_annualized.to_f
            }
          end,
          by_country: by_country.map do |c|
            {
              id: c.country_id,
              name: c.country_name,
              code: c.country_code,
              employee_count: c.employee_count.to_i,
              avg_annualized: c.avg_annualized.to_f,
              min_annualized: c.min_annualized.to_f,
              max_annualized: c.max_annualized.to_f
            }
          end,
          distribution_buckets: buckets
        }
      end
    end
  end
end
