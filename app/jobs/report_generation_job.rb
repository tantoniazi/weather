class ReportGenerationJob < ApplicationJob
  queue_as :reports

  def perform(user_id, filters, format, report_id)
    user = User.find(user_id)
    report_service = WeatherReportService.new(user, filters)

    begin
      # Gerar o relatório
      report_data = report_service.generate_report(format.to_sym)

      # Salvar o relatório gerado
      report = Report.find(report_id)
      report.update!(
        status: "completed",
        file_data: report_data,
        completed_at: Time.current,
      )

      # Enviar notificação por email (opcional)
      ReportMailer.report_ready(user, report).deliver_now if report.email_notification?

      Rails.logger.info "Relatório #{report_id} gerado com sucesso para usuário #{user.email}"
    rescue => e
      Rails.logger.error "Erro ao gerar relatório #{report_id}: #{e.message}"

      # Atualizar status para erro
      report = Report.find(report_id)
      report.update!(
        status: "failed",
        error_message: e.message,
        completed_at: Time.current,
      )

      # Re-raise para que o Sidekiq possa fazer retry se necessário
      raise e
    end
  end
end
