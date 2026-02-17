class SaleTicketService
  attr_reader :sale, :user, :company, :print_number
  
  def initialize(sale, user)
    @sale = sale
    @user = user
    @company = Company.current
    @print_number = sale.next_print_number
  end
  
  def generate_pdf
    # Registrar la impresión ANTES de generar el PDF
    register_printing
    
    # Generar el PDF
    create_pdf
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
  
  def create_pdf
    Prawn::Document.new(
      page_size: [226.77, 841.89], # 80mm ancho (térmica)
      margin: [10, 30, 10, 20]      # Margen: [top, right, bottom, left]
    ) do |pdf|
      # Header de la empresa
      draw_company_header(pdf)
      
      # Separador
      pdf.move_down 5
      draw_separator(pdf)
      pdf.move_down 5
      
      # Info del ticket
      draw_ticket_info(pdf)
      
      # Separador
      pdf.move_down 5
      draw_separator(pdf)
      pdf.move_down 5
      
      # Productos
      draw_products(pdf)
      
      # Separador
      pdf.move_down 5
      draw_separator(pdf)
      pdf.move_down 5
      
      # Totales
      draw_totals(pdf)
      
      # Separador
      pdf.move_down 5
      draw_separator(pdf)
      pdf.move_down 5
      
      # Pago
      draw_payment(pdf)
      
      # Separador
      pdf.move_down 5
      draw_separator(pdf)
      pdf.move_down 5
      
      # Footer
      draw_footer(pdf)
      
      # Si es reimpresión, agregar marca
      if print_number > 1
        pdf.move_down 5
        draw_separator(pdf)
        pdf.move_down 5
        draw_reprint_info(pdf)
      end
    end.render
  end
  
  def draw_company_header(pdf)
    # Nombre de la empresa
    pdf.text company.display_name, 
      size: 14, 
      style: :bold, 
      align: :center

      pdf.move_down 3
    
    # RFC
    if company.rfc.present?
      pdf.text "RFC: #{company.rfc.upcase}", 
        size: 8, 
        align: :center
    end
    
    # Teléfono
    if company.phone.present?
      pdf.text "Tel: #{company.phone}", 
        size: 8, 
        align: :center
    end
    
    # Dirección
    if company.full_address.present?
      pdf.text company.full_address, 
        size: 7, 
        align: :center
    end
  end
  
  def draw_separator(pdf)
    pdf.text "=" * 32, size: 8, align: :center
  end
  
  def draw_ticket_info(pdf)
    # Número de ticket
    ticket_label = print_number > 1 ? "Ticket: ##{sale.id}  COPIA (#{print_number})" : "Ticket: ##{sale.id}"
    pdf.text ticket_label, size: 10, style: :bold
    
    # Fecha y hora
    pdf.text "Fecha: #{I18n.l(sale.created_at, format: :short)}", size: 8
    
    # Cliente
    if sale.customer
      pdf.text "Cliente: #{sale.customer.name}", size: 8, style: :bold
    end

    # Cajero
    cajero_name = sale.user.name.presence || sale.user.email
    pdf.text "Cajero: #{cajero_name}", size: 8
      
    # Caja (si existe)
    if sale.register_session
      pdf.text "Caja: #{sale.register_session.register.name}", size: 8
    end
  end
  
  def draw_products(pdf)
    pdf.text "PRODUCTOS", size: 9, style: :bold
    pdf.move_down 3
    
    sale.sale_items.includes(:product).each do |item|
      # Nombre del producto
      pdf.text item.product.name, size: 8, style: :bold
      
      # Cantidad × Precio = Subtotal
      line = sprintf("  %s x $%.2f = $%.2f", 
        format_quantity(item.quantity),
        item.unit_price,
        item.subtotal
      )
      pdf.text line, size: 8
      
      # Descuento si existe
      if item.discount > 0
        pdf.text "  Descuento: -$#{sprintf('%.2f', item.discount)}", size: 7, color: 'FF0000'
      end
      
      pdf.move_down 2
    end
  end
  
  def draw_totals(pdf)
    # Calcular subtotal y descuento desde items
    subtotal = sale.sale_items.sum(&:subtotal)
    total_discount = sale.sale_items.sum(&:discount)
    
    # Subtotal
    pdf.text "Subtotal: $#{sprintf('%.2f', subtotal)}", 
      size: 9, 
      align: :right
    
    # Descuento total
    if total_discount > 0
      pdf.text "Descuento: -$#{sprintf('%.2f', total_discount)}", 
        size: 9, 
        align: :right,
        style: :bold
    end
    
    # Total
    pdf.move_down 3
    pdf.text "TOTAL: $#{sprintf('%.2f', sale.total)}", 
      size: 12, 
      style: :bold, 
      align: :right
  end
  
  def draw_payment(pdf)
    pdf.text "Metodo de pago: #{payment_method_label}", size: 8
    
    # Si es efectivo y tiene datos de recibido/cambio
    if sale.payment_method == 'cash' && sale.amount_received.present?
      pdf.move_down 2
      pdf.text "Recibido: $#{sprintf('%.2f', sale.amount_received)}", size: 8
      
      if sale.change_given && sale.change_given > 0
        pdf.text "Cambio: $#{sprintf('%.2f', sale.change_given)}", size: 8, style: :bold
      end
    end
  end
  
  def draw_footer(pdf)
    pdf.text "¡GRACIAS POR SU COMPRA!", 
      size: 10, 
      style: :bold, 
      align: :center
    
    pdf.move_down 3
    pdf.text "Vuelva Pronto", 
      size: 8, 
      align: :center

    # Espacio en blanco para que el ticket salga completamente
    pdf.move_down 20
    pdf.text " ", size: 1  # Línea invisible para forzar espacio
  end
  
  def draw_reprint_info(pdf)
    pdf.text "*** REIMPRESIÓN ***", 
      size: 9, 
      style: :bold, 
      align: :center
    
      reprint_user_name = user.name.presence || user.email
      pdf.text "Reimpreso por: #{reprint_user_name}", 
      size: 7, 
      align: :center
    
    pdf.text "Reimpreso: #{I18n.l(Time.current, format: :short)}", 
      size: 7, 
      align: :center
  end
  
  def format_quantity(quantity)
    # Si es entero, mostrar sin decimales
    quantity % 1 == 0 ? quantity.to_i.to_s : sprintf('%.3f', quantity)
  end
  
  def payment_method_label
    case sale.payment_method
    when 'cash' then 'Efectivo'
    when 'card' then 'Tarjeta'
    when 'credit' then 'Crédito'
    when 'mixed' then 'Mixto'
    else sale.payment_method
    end
  end
end