class ReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    @weathers = filtered_weathers.page(params[:page]).per(10)
    @total_count = filtered_weathers.count

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

    report_service = WeatherReportService.new(current_user, filter_params)

    begin
      case format
      when "csv"
        send_data report_service.generate_report(:csv),
                  filename: "relatorio_clima_#{Date.current.strftime("%Y%m%d")}.csv",
                  type: "text/csv"
      when "xlsx"
        send_data report_service.generate_report(:xlsx),
                  filename: "relatorio_clima_#{Date.current.strftime("%Y%m%d")}.xlsx",
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      when "pdf"
        send_data report_service.generate_report(:pdf),
                  filename: "relatorio_clima_#{Date.current.strftime("%Y%m%d")}.pdf",
                  type: "application/pdf"
      end
    rescue => e
      Rails.logger.error "Erro ao gerar relatório: #{e.message}"
      redirect_to reports_path, alert: "Erro ao gerar relatório: #{e.message}"
    end
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
