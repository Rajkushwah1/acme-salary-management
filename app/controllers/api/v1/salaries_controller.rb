module Api
  module V1
    class SalariesController < ApplicationController
      before_action :set_employee, only: [:index, :revise]
      before_action :set_salary_record, only: [:correct]

      # GET /api/v1/employees/:employee_id/salaries
      # Chronological salary timeline and history for a specific employee
      def index
        records = @employee.salary_records.order(effective_from: :desc)
        render json: {
          employee: {
            id: @employee.id,
            employee_code: @employee.employee_code,
            full_name: @employee.full_name,
            status: @employee.status
          },
          salary_records: records.map { |r| salary_payload(r) }
        }
      end

      # POST /api/v1/employees/:employee_id/salaries
      # Salary revision (promotion, annual raise, compensation change)
      def revise
        new_record = @employee.revise_salary!(
          revision_params,
          actor: current_user,
          reason: params.require(:reason)
        )

        render json: { salary_record: salary_payload(new_record) }, status: :created
      end

      # PATCH /api/v1/salaries/:id/correct
      # Corrects an existing salary record in place for clerical remediation
      def correct
        reason = params.require(:reason)
        employee = @salary_record.employee

        corrected = employee.correct_salary!(
          @salary_record.id,
          correction_params,
          actor: current_user,
          reason: reason
        )

        render json: { salary_record: salary_payload(corrected) }, status: :ok
      end

      private

      def set_employee
        @employee = Employee.find(params[:employee_id])
      end

      def set_salary_record
        @salary_record = SalaryRecord.find(params[:id])
      end

      def revision_params
        params.require(:salary).permit(:base_salary, :currency, :pay_frequency, :effective_from, :effective_to)
      end

      def correction_params
        params.require(:salary).permit(:base_salary, :currency, :pay_frequency, :effective_from, :effective_to)
      end

      def salary_payload(record)
        {
          id: record.id,
          employee_id: record.employee_id,
          base_salary: record.base_salary,
          currency: record.currency,
          pay_frequency: record.pay_frequency,
          effective_from: record.effective_from,
          effective_to: record.effective_to,
          annualized_salary: record.annualized_salary,
          created_at: record.created_at
        }
      end
    end
  end
end
