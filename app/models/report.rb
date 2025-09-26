class Report < ApplicationRecord
  belongs_to :user

  # Validações
  validates :format, presence: true, inclusion: { in: %w[csv xlsx pdf] }
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }
  validates :filters, presence: true

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :recent, -> { order(created_at: :desc) }

  # Serialização dos filtros
  serialize :filters, coder: JSON

  # Métodos de status
  def pending?
    status == "pending"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def filename
    "relatorio_clima_#{created_at.strftime("%Y%m%d_%H%M%S")}.#{format}"
  end

  def content_type
    case format
    when "csv"
      "text/csv"
    when "xlsx"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    when "pdf"
      "application/pdf"
    end
  end

  def file_size
    file_data&.size || 0
  end

  def file_size_human
    return "0 B" if file_size == 0

    units = %w[B KB MB GB]
    size = file_size.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end

    "#{size.round(2)} #{units[unit_index]}"
  end

  def processing_time
    return nil unless completed_at && created_at
    completed_at - created_at
  end

  def processing_time_human
    return "N/A" unless processing_time

    if processing_time < 1.minute
      "#{(processing_time * 1000).round}ms"
    elsif processing_time < 1.hour
      "#{(processing_time / 1.minute).round(1)}min"
    else
      "#{(processing_time / 1.hour).round(1)}h"
    end
  end
end
