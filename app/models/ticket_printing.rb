class TicketPrinting < ApplicationRecord
  # ==================== ASOCIACIONES ====================
  
  belongs_to :sale
  belongs_to :user
  
  # ==================== VALIDACIONES ====================
  
  validates :print_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :printed_at, presence: true
  validates :print_number, uniqueness: { scope: :sale_id }
  
  # ==================== SCOPES ====================
  
  scope :ordered, -> { order(print_number: :asc) }
  scope :recent, -> { order(printed_at: :desc) }
  
  # ==================== MÉTODOS DE CLASE ====================
  
  def self.next_print_number(sale)
    where(sale: sale).maximum(:print_number).to_i + 1
  end
  
  # ==================== MÉTODOS DE INSTANCIA ====================
  
  def original?
    print_number == 1
  end
  
  def copy?
    !original?
  end
  
  def copy_label
    return "Original" if original?
    "Copia (#{print_number})"
  end
end