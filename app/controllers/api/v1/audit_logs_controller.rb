module Api
  module V1
    class AuditLogsController < ApplicationController
      # GET /api/v1/audit_logs
      # Paginated audit history across the organization or scoped to an employee
      def index
        scope = SalaryAuditLog.includes(:user, :employee).order(created_at: :desc)
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where(action: params[:action_type]) if params[:action_type].present?

        total_count = scope.count
        page = [params[:page].to_i, 1].max
        per_page = [[params[:per_page].to_i, 1].max, 100].min
        per_page = 25 if params[:per_page].blank?

        logs = scope.offset((page - 1) * per_page).limit(per_page)

        render json: {
          audit_logs: logs.map { |log| audit_log_payload(log) },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: (total_count.to_f / per_page).ceil
          }
        }
      end

      private

      def audit_log_payload(log)
        {
          id: log.id,
          employee: {
            id: log.employee.id,
            employee_code: log.employee.employee_code,
            full_name: log.employee.full_name
          },
          actor: {
            id: log.user.id,
            name: log.user.full_name,
            email: log.user.email
          },
          action: log.action,
          previous_salary: log.previous_salary,
          new_salary: log.new_salary,
          previous_currency: log.previous_currency,
          new_currency: log.new_currency,
          previous_pay_frequency: log.previous_pay_frequency,
          new_pay_frequency: log.new_pay_frequency,
          previous_effective_from: log.previous_effective_from,
          new_effective_from: log.new_effective_from,
          previous_effective_to: log.previous_effective_to,
          new_effective_to: log.new_effective_to,
          reason: log.reason,
          created_at: log.created_at
        }
      end
    end
  end
end
