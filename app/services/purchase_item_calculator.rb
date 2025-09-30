class PurchaseItemCalculator
  def initialize(purchase_item)
    @purchase_item = purchase_item
  end

  def calculate!
    # Subtotal de lo que se compró
    @purchase_item.subtotal = @purchase_item.quantity.to_f * @purchase_item.purchase_price.to_f

    # Costo por pieza
    if @purchase_item.conversion_factor.to_f > 0
      @purchase_item.cost_per_piece = @purchase_item.purchase_price.to_f / @purchase_item.conversion_factor.to_f
    else
      @purchase_item.cost_per_piece = @purchase_item.purchase_price.to_f
    end
  end
end
