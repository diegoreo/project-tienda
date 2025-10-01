class InventoryMovement < ApplicationRecord
  belongs_to :inventory
  belongs_to :source, polymorphic: true, optional: true

  # Definimos enums con enteros (más seguros en Rails 8)
  enum :movement_type, { incoming: 0, outgoing: 1 }
  enum :reason, {
    initial_stock: 0,       # Carga inicial
    purchase: 1,            # Compra a proveedor
    sale: 2,                # Venta a cliente
    return_from_client: 3,  # Devolución de cliente
    return_to_supplier: 4,  # Devolución al proveedor
    transfer_in: 5,         # Transferencia entrante
    transfer_out: 6,        # Transferencia saliente
    waste: 7,               # Merma (caducidad, rotura)
    adjustment: 8,          # Ajuste manual
    donation: 9,            # Donación (entrada/salida)
    other: 10,              # Otro motivo no clasificado
    purchase_cancellation: 11  # Eliminación de compra
  }
  
  validates :movement_type, presence: true
  validates :reason, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  # Definimos qué motivos son válidos para cada tipo de movimiento
  VALID_REASONS_BY_TYPE = {
    "incoming" => %i[initial_stock purchase return_from_client transfer_in donation other adjustment],
    "outgoing" => %i[sale return_to_supplier transfer_out waste other adjustment purchase_cancellation]
  }.freeze

  validate :reason_allowed_for_movement_type

  private

  def reason_allowed_for_movement_type
    allowed_reasons = VALID_REASONS_BY_TYPE[movement_type]
    return if allowed_reasons.include?(reason.to_sym)

    errors.add(:reason, "'#{reason}' no es válido para un movimiento de tipo '#{movement_type}'")
  end
end