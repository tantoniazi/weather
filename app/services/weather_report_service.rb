require "csv"
require "prawn"
require "prawn/table"

class WeatherReportService
  attr_reader :user, :filters

  def initialize(user, filters = {})
    @user = user
    @filters = filters.with_indifferent_access
  end

  def generate_report(format = :csv)
    case format.to_sym
    when :csv
      generate_csv
    when :xlsx
      generate_xlsx
    when :pdf
      generate_pdf
    else
      raise ArgumentError, "Formato não suportado: #{format}"
    end
  end

  def filtered_weathers
    scope = user.weathers.includes(:user).order(created_at: :desc)

    if filters[:zip_code].present?
      scope = scope.where("zip ILIKE ?", "%#{filters[:zip_code]}%")
    end

    if filters[:created_at_start].present?
      scope = scope.where("created_at >= ?", filters[:created_at_start])
    end

    if filters[:created_at_end].present?
      scope = scope.where("created_at <= ?", filters[:created_at_end])
    end

    scope
  end

  private

  def generate_csv
    CSV.generate(headers: true) do |csv|
      csv << csv_headers

      filtered_weathers.find_each do |weather|
        csv << [
          weather.zip,
          weather.temperature,
          weather.temp_min,
          weather.temp_max,
          weather.description,
          weather.created_at.strftime("%d/%m/%Y %H:%M"),
          weather.user.email,
        ]
      end
    end
  end

  def generate_xlsx
    # Implementação usando caxlsx
    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Relatório de Clima") do |sheet|
      # Cabeçalhos
      sheet.add_row csv_headers, style: workbook.styles.add_style(
                     b: true,
                     bg_color: "DDDDDD",
                     border: { style: :thin, color: "000000" },
                   )

      # Dados
      filtered_weathers.find_each do |weather|
        sheet.add_row [
          weather.zip,
          weather.temperature,
          weather.temp_min,
          weather.temp_max,
          weather.description,
          weather.created_at.strftime("%d/%m/%Y %H:%M"),
          weather.user.email,
        ]
      end

      # Auto ajustar largura das colunas
      sheet.column_widths 12, 12, 12, 12, 20, 18, 25
    end

    package.to_stream.read
  end

  def generate_pdf
    Prawn::Document.new do |pdf|
      # Título
      pdf.text "Relatório de Consultas de Clima", size: 20, style: :bold, align: :center
      pdf.move_down 10

      # Informações do relatório
      pdf.text "Usuário: #{user.email}", size: 12
      pdf.text "Gerado em: #{Time.current.strftime("%d/%m/%Y %H:%M")}", size: 12
      pdf.text "Total de registros: #{filtered_weathers.count}", size: 12
      pdf.move_down 20

      # Filtros aplicados
      if filters.any?
        pdf.text "Filtros aplicados:", size: 14, style: :bold
        filters.each do |key, value|
          next if value.blank?

          filter_name = case key.to_s
            when "zip_code" then "CEP"
            when "created_at_start" then "Data início"
            when "created_at_end" then "Data fim"
            else key.humanize
            end

          pdf.text "#{filter_name}: #{value}", size: 12
        end
        pdf.move_down 20
      end

      # Tabela de dados
      if filtered_weathers.any?
        data = [pdf_headers]

        filtered_weathers.limit(100).each do |weather| # Limitar para não sobrecarregar o PDF
          data << [
            weather.zip,
            "#{weather.temperature}°C",
            "#{weather.temp_min}°C",
            "#{weather.temp_max}°C",
            weather.description,
            weather.created_at.strftime("%d/%m/%Y\n%H:%M"),
          ]
        end

        pdf.table data, header: true, row_colors: ["FFFFFF", "F0F0F0"] do
          row(0).font_style = :bold
          row(0).background_color = "DDDDDD"
          columns(0..5).align = :center
          column(4).width = 120 # Descrição mais larga
        end

        if filtered_weathers.count > 100
          pdf.move_down 10
          pdf.text "* Mostrando apenas os primeiros 100 registros", size: 10, style: :italic
        end
      else
        pdf.text "Nenhum registro encontrado com os filtros aplicados.", size: 14, align: :center
      end

      # Rodapé
      pdf.number_pages "Página <page> de <total>", at: [pdf.bounds.right - 100, 0], width: 100, align: :right
    end.render
  end

  def csv_headers
    ["CEP", "Temperatura", "Temp. Mín", "Temp. Máx", "Descrição", "Data/Hora", "Usuário"]
  end

  def pdf_headers
    ["CEP", "Temp.", "Mín.", "Máx.", "Descrição", "Data/Hora"]
  end

  def self.available_formats
    %w[csv xlsx pdf]
  end

  def self.format_description(format)
    case format.to_s
    when "csv"
      "CSV - Valores separados por vírgula"
    when "xlsx"
      "Excel - Planilha do Microsoft Excel"
    when "pdf"
      "PDF - Documento portátil"
    else
      "Formato desconhecido"
    end
  end
end
