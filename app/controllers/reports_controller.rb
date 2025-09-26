class ReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    @weathers = filtered_weathers.page(params[:page]).per(10)
    @total_count = filtered_weathers.count
    @reports = current_user.reports.recent.page(params[:reports_page]).per(5)

    respond_to do |format|
      format.html
      format.json { render json: @weathers }
    end
  end

  def export
    format = params[:format]&.downcase || "csv"

    unless WeatherReportService.available_formats.include?(format)
      redirect_to reports_path, alert: "Formato de exportação inválido"
      return
    end

    # Criar registro do relatório
    report = current_user.reports.create!(
      format: format,
      status: "pending",
      filters: filter_params.to_h,
      email_notification: params[:email_notification] == "1",
    )

    # Enfileirar job para processamento em background
    ReportGenerationJob.perform_later(
      current_user.id,
      filter_params.to_h,
      format,
      report.id
    )

    redirect_to reports_path, notice: "Relatório sendo gerado em background. Você será notificado quando estiver pronto."
  end

  def download
    report = current_user.reports.find(params[:id])

    unless report.completed?
      redirect_to reports_path, alert: "Relatório ainda não está pronto."
      return
    end

    send_data report.file_data,
              filename: report.filename,
              type: report.content_type
  end

  private

  def filtered_weathers
    @report_service = WeatherReportService.new(current_user, filter_params)
    @report_service.filtered_weathers
  end

  def filter_params
    params.permit(:zip_code, :created_at_start, :created_at_end)
  end
end
