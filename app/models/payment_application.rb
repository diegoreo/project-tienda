class PaymentApplication < ApplicationRecord
  has_paper_trail
  # Relaciones
  belongs_to :payment
  belongs_to :sale

  # Validaciones
  validates :amount_applied, presence: true, numericality: { greater_than: 0 }
  validate :amount_cannot_exceed_payment_amount
  validate :amount_cannot_exceed_sale_pending

  # Scopes
  scope :by_payment, ->(payment_id) { where(payment_id: payment_id) }
  scope :by_sale, ->(sale_id) { where(sale_id: sale_id) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def amount_cannot_exceed_payment_amount
    if payment && amount_applied && amount_applied > payment.amount
      errors.add(:amount_applied, "no puede ser mayor al monto del pago")
    end
  end

  def amount_cannot_exceed_sale_pending
    if sale && amount_applied && amount_applied > sale.pending_amount
      errors.add(:amount_applied, "no puede ser mayor al saldo pendiente de la venta")
    end
  end
end
