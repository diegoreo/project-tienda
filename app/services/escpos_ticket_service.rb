class EscposTicketService
  attr_reader :sale, :user, :company, :print_number
  
  def initialize(sale, user)
    @sale = sale
    @user = user
    @company = Company.current
    @print_number = sale.next_print_number
  end
  
  def generate_commands
    # Registrar la impresión
    register_printing
    
    # Generar comandos ESC/POS como array de strings
    commands = []
    
    # Inicializar impresora
    commands << "\x1B\x40" # ESC @ - Inicializar
    
    # Header de empresa
    commands.concat(build_header)
    
    # Separador
    commands << line_separator
    
    # Info del ticket
    commands.concat(build_ticket_info)
    
    # Separador
    commands << line_separator
    
    # Productos
    commands.concat(build_products)
    
    # Separador
    commands << line_separator
    
    # Totales
    commands.concat(build_totals)
    
    # Separador
    commands << line_separator
    
    # Método de pago
    commands.concat(build_payment)
    
    # Separador
    commands << line_separator
    
    # Footer
    commands.concat(build_footer)
    
    # Si es reimpresión
    if print_number > 1
      commands << line_separator
      commands.concat(build_reprint_info)
    end
    
    # Feed y corte
    commands << "\n\n\n"           # Feed (avanzar papel)
    commands << "\x1D\x56\x00"     # Corte parcial
    
    # Retornar como JSON
    {
      commands: commands,
      sale_id: sale.id,
      print_number: print_number
    }
  end
  
  private
  
  def register_printing
    TicketPrinting.create!(
      sale: sale,
      user: user,
      print_number: print_number,
      printed_at: Time.current
    )
  end
  
  def build_header
    lines = []
    
    # Nombre empresa (centrado, negrita, tamaño grande)
    lines << center_text(company.display_name, bold: true)
    
    # RFC
    lines << center_text("RFC: #{company.rfc.upcase}") if company.rfc.present?
    
    # Teléfono
    lines << center_text("Tel: #{company.phone}") if company.phone.present?
    
    # Dirección
    lines << center_text(company.full_address) if company.full_address.present?
    
    lines << "\n"
    lines
  end
  
  def build_ticket_info
    lines = []
    
    # Número de ticket
    ticket_label = print_number > 1 ? "Ticket: ##{sale.id}  COPIA (#{print_number})" : "Ticket: ##{sale.id}"
    lines << "#{ticket_label}\n"
    
    # Fecha
    lines << "Fecha: #{I18n.l(sale.created_at, format: :short)}\n"
    
    # Cliente
    if sale.customer
      lines << "Cliente: #{sale.customer.name}\n"
    end
    
    # Cajero
    cajero_name = sale.user.name.presence || sale.user.email
    lines << "Cajero: #{cajero_name}\n"
    
    # Caja
    if sale.register_session
      lines << "Caja: #{sale.register_session.register.name}\n"
    end
    
    lines << "\n"
    lines
  end
  
  def build_products
    lines = []
    lines << "PRODUCTOS\n"
    
    sale.sale_items.includes(:product).each do |item|
      # Nombre producto
      lines << "#{item.product.name}\n"
      
      # Cantidad x Precio = Subtotal
      qty = format_quantity(item.quantity)
      price = sprintf('%.2f', item.unit_price)
      subtotal = sprintf('%.2f', item.subtotal)
      lines << "  #{qty} x $#{price} = $#{subtotal}\n"
      
      # Descuento
      if item.discount > 0
        lines << "  Descuento: -$#{sprintf('%.2f', item.discount)}\n"
      end
    end
    
    lines << "\n"
    lines
  end
  
  def build_totals
    lines = []
    
    # Calcular
    subtotal = sale.sale_items.sum(&:subtotal)
    total_discount = sale.sale_items.sum(&:discount)
    
    # Subtotal
    lines << align_right("Subtotal: $#{sprintf('%.2f', subtotal)}")
    
    # Descuento
    if total_discount > 0
      lines << align_right("Descuento: -$#{sprintf('%.2f', total_discount)}")
    end
    
    # Total (más grande)
    lines << align_right("TOTAL: $#{sprintf('%.2f', sale.total)}", large: true)
    
    lines << "\n"
    lines
  end
  
  def build_payment
    lines = []
    lines << "Metodo de pago: #{payment_method_label}\n"
    
    # Si es efectivo y tiene datos de recibido/cambio
    if sale.payment_method == 'cash' && sale.amount_received.present?
      lines << "Recibido: $#{sprintf('%.2f', sale.amount_received)}\n"
      
      if sale.change_given && sale.change_given > 0
        lines << "Cambio: $#{sprintf('%.2f', sale.change_given)}\n"
      end
    end
    
    lines << "\n"
    lines
  end
  
  def build_footer
    lines = []
    lines << center_text("GRACIAS POR SU COMPRA", bold: true)
    lines << center_text("Vuelva Pronto")
    lines << "\n"
    lines
  end
  
  def build_reprint_info
    lines = []
    lines << center_text("*** REIMPRESION ***", bold: true)
    
    reprint_user_name = user.name.presence || user.email
    lines << center_text("Reimpreso por: #{reprint_user_name}")
    lines << center_text("Reimpreso: #{I18n.l(Time.current, format: :short)}")
    
    lines << "\n"
    lines
  end
  
  # Helpers
  
  def line_separator
    "================================\n"
  end
  
  def center_text(text, bold: false)
    line = text.to_s
    line = "\x1B\x45\x01#{line}\x1B\x45\x00" if bold # ESC E - Bold
    
    # Calcular espacios para centrar (evitar negativos)
    spaces = ((48 - text.length) / 2).clamp(0, 48)
    line = "#{' ' * spaces}#{line}"
    
    "#{line}\n"
  end
  
  def align_right(text, large: false)
    spaces = (48 - text.length).clamp(0, 48)
    line = "#{' ' * spaces}#{text}"
    line = "\x1D\x21\x11#{line}\x1D\x21\x00" if large # GS ! - Tamaño doble
    "#{line}\n"
  end
  
  def format_quantity(quantity)
    quantity % 1 == 0 ? quantity.to_i.to_s : sprintf('%.3f', quantity)
  end
  
  def payment_method_label
    case sale.payment_method
    when 'cash' then 'Efectivo'
    when 'card' then 'Tarjeta'
    when 'credit' then 'Credito'
    when 'mixed' then 'Mixto'
    else sale.payment_method
    end
  end
end