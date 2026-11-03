module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :set_employee, only: [:show, :update, :deactivate]

      # GET /api/v1/employees
      # Server-side pagination, search, and multi-facet filtering (country, dept, status)
      def index
        scope = Employee.includes(:country, :department, :salary_records)

        # Filters
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(country_id: params[:country_id]) if params[:country_id].present?
        scope = scope.where(department_id: params[:department_id]) if params[:department_id].present?

        # Search across full name, employee code, and email using Trigram index
        if params[:search].present?
          query = "%#{params[:search].strip}%"
          scope = scope.where(
            "first_name ILIKE :q OR last_name ILIKE :q OR employee_code ILIKE :q OR email ILIKE :q",
            q: query
          )
        end

        total_count = scope.count
        page = [params[:page].to_i, 1].max
        per_page = [[params[:per_page].to_i, 1].max, 100].min
        per_page = 25 if params[:per_page].blank?

        employees = scope.order(created_at: :desc)
                         .offset((page - 1) * per_page)
                         .limit(per_page)

        render json: {
          employees: employees.map { |emp| employee_summary_payload(emp) },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: (total_count.to_f / per_page).ceil
          }
        }
      end

      # GET /api/v1/employees/:id
      def show
        render json: { employee: employee_detail_payload(@employee) }
      end

      # POST /api/v1/employees
      # Atomic creation of employee with initial salary record and initial audit log
      def create
        ActiveRecord::Base.transaction do
          country = Country.find(employee_params[:country_id])
          department = Department.find(employee_params[:department_id])

          @employee = Employee.create!(
            employee_code: employee_params[:employee_code],
            first_name: employee_params[:first_name],
            last_name: employee_params[:last_name],
            email: employee_params[:email],
            country: country,
            department: department,
            designation: employee_params[:designation],
            status: "active",
            joined_at: employee_params[:joined_at] || Date.current
          )

          initial_salary = @employee.salary_records.create!(
            base_salary: salary_params[:base_salary],
            currency: salary_params[:currency] || country.default_currency,
            pay_frequency: salary_params[:pay_frequency] || "annual",
            effective_from: salary_params[:effective_from] || @employee.joined_at,
            effective_to: salary_params[:effective_to]
          )

          @employee.salary_audit_logs.create!(
            user: current_user,
            salary_record: initial_salary,
            action: "initial_creation",
            new_salary: initial_salary.base_salary,
            new_currency: initial_salary.currency,
            new_pay_frequency: initial_salary.pay_frequency,
            new_effective_from: initial_salary.effective_from,
            new_effective_to: initial_salary.effective_to,
            reason: "Initial employee onboarding compensation"
          )
        end

        render json: { employee: employee_detail_payload(@employee) }, status: :created
      end

      # PATCH /api/v1/employees/:id
      def update
        @employee.update!(employee_update_params)
        render json: { employee: employee_detail_payload(@employee) }
      end

      # POST /api/v1/employees/:id/deactivate
      def deactivate
        reason = params[:reason].presence || "Employee deactivation requested via HR"
        @employee.deactivate!(actor: current_user, reason: reason)
        render json: { employee: employee_detail_payload(@employee) }
      end

      private

      def set_employee
        @employee = Employee.includes(:country, :department, :salary_records).find(params[:id])
      end

      def employee_params
        params.require(:employee).permit(
          :employee_code, :first_name, :last_name, :email,
          :country_id, :department_id, :designation, :joined_at
        )
      end

      def salary_params
        params.require(:salary).permit(
          :base_salary, :currency, :pay_frequency, :effective_from, :effective_to
        )
      end

      def employee_update_params
        params.require(:employee).permit(
          :first_name, :last_name, :email, :country_id, :department_id, :designation
        )
      end

      def employee_summary_payload(emp)
        current_sal = emp.current_salary_record
        {
          id: emp.id,
          employee_code: emp.employee_code,
          first_name: emp.first_name,
          last_name: emp.last_name,
          full_name: emp.full_name,
          email: emp.email,
          designation: emp.designation,
          status: emp.status,
          joined_at: emp.joined_at,
          country: { id: emp.country.id, name: emp.country.name, code: emp.country.code },
          department: { id: emp.department.id, name: emp.department.name, code: emp.department.code },
          current_salary: current_sal ? {
            base_salary: current_sal.base_salary,
            currency: current_sal.currency,
            pay_frequency: current_sal.pay_frequency,
            effective_from: current_sal.effective_from,
            effective_to: current_sal.effective_to
          } : nil
        }
      end

      def employee_detail_payload(emp)
        payload = employee_summary_payload(emp)
        payload[:salary_records] = emp.salary_records.order(effective_from: :desc).map do |sal|
          {
            id: sal.id,
            base_salary: sal.base_salary,
            currency: sal.currency,
            pay_frequency: sal.pay_frequency,
            effective_from: sal.effective_from,
            effective_to: sal.effective_to,
            annualized_salary: sal.annualized_salary
          }
        end
        payload
      end
    end
  end
end
