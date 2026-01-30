class Company < ApplicationRecord
  # ==================== CONSTANTES ====================
  
  PLANS = %w[free basic premium].freeze
  
  MEXICAN_STATES = [
    'Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche',
    'Chiapas', 'Chihuahua', 'Coahuila', 'Colima', 'Ciudad de México',
    'Durango', 'Guanajuato', 'Guerrero', 'Hidalgo', 'Jalisco', 'México',
    'Michoacán', 'Morelos', 'Nayarit', 'Nuevo León', 'Oaxaca', 'Puebla',
    'Querétaro', 'Quintana Roo', 'San Luis Potosí', 'Sinaloa', 'Sonora',
    'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas'
  ].freeze

  REGIMENES_FISCALES = [
    ['601 - General de Ley Personas Morales', '601'],
    ['603 - Personas Morales con Fines no Lucrativos', '603'],
    ['605 - Sueldos y Salarios e Ingresos Asimilados a Salarios', '605'],
    ['606 - Arrendamiento', '606'],
    ['607 - Régimen de Enajenación o Adquisición de Bienes', '607'],
    ['608 - Demás ingresos', '608'],
    ['610 - Residentes en el Extranjero sin Establecimiento Permanente en México', '610'],
    ['611 - Ingresos por Dividendos (socios y accionistas)', '611'],
    ['612 - Personas Físicas con Actividades Empresariales y Profesionales', '612'],
    ['614 - Ingresos por intereses', '614'],
    ['615 - Régimen de los ingresos por obtención de premios', '615'],
    ['616 - Sin obligaciones fiscales', '616'],
    ['620 - Sociedades Cooperativas de Producción que optan por diferir sus ingresos', '620'],
    ['621 - Incorporación Fiscal', '621'],
    ['622 - Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras', '622'],
    ['623 - Opcional para Grupos de Sociedades', '623'],
    ['624 - Coordinados', '624'],
    ['625 - Régimen de las Actividades Empresariales con ingresos a través de Plataformas Tecnológicas', '625'],
    ['626 - Régimen Simplificado de Confianza', '626']
  ].freeze

  USOS_CFDI = [
    ['G01 - Adquisición de mercancías', 'G01'],
    ['G02 - Devoluciones, descuentos o bonificaciones', 'G02'],
    ['G03 - Gastos en general', 'G03'],
    ['I01 - Construcciones', 'I01'],
    ['I02 - Mobilario y equipo de oficina por inversiones', 'I02'],
    ['I03 - Equipo de transporte', 'I03'],
    ['I04 - Equipo de computo y accesorios', 'I04'],
    ['I05 - Dados, troqueles, moldes, matrices y herramental', 'I05'],
    ['I06 - Comunicaciones telefónicas', 'I06'],
    ['I07 - Comunicaciones satelitales', 'I07'],
    ['I08 - Otra maquinaria y equipo', 'I08'],
    ['D01 - Honorarios médicos, dentales y gastos hospitalarios', 'D01'],
    ['D02 - Gastos médicos por incapacidad o discapacidad', 'D02'],
    ['D03 - Gastos funerales', 'D03'],
    ['D04 - Donativos', 'D04'],
    ['D05 - Intereses reales efectivamente pagados por créditos hipotecarios', 'D05'],
    ['D06 - Aportaciones voluntarias al SAR', 'D06'],
    ['D07 - Primas por seguros de gastos médicos', 'D07'],
    ['D08 - Gastos de transportación escolar obligatoria', 'D08'],
    ['D09 - Depósitos en cuentas para el ahorro, primas que tengan como base planes de pensiones', 'D09'],
    ['D10 - Pagos por servicios educativos (colegiaturas)', 'D10'],
    ['S01 - Sin efectos fiscales', 'S01'],
    ['CP01 - Pagos', 'CP01'],
    ['CN01 - Nómina', 'CN01']
  ].freeze
  
  # ==================== VALIDACIONES ====================
  
  # Nombre comercial (siempre requerido internamente)
  validates :business_name, presence: true, length: { maximum: 100 }
  
  # RFC (opcional pero si existe debe ser válido)
  validates :rfc, length: { is: 13 }, allow_blank: true
  validates :rfc, format: { 
    with: /\A[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}\z/i, 
    message: "formato inválido (debe ser 13 caracteres: XAXX010101000)" 
  }, allow_blank: true
  validates :rfc, uniqueness: { case_sensitive: false }, allow_blank: true
  
  # Email (opcional pero si existe debe ser válido)
  validates :email, format: { 
    with: URI::MailTo::EMAIL_REGEXP,
    message: "formato inválido"
  }, allow_blank: true
  validates :email, length: { maximum: 100 }, allow_blank: true
  
  # Teléfono (opcional, formato flexible)
  validates :phone, length: { maximum: 20 }, allow_blank: true
  validates :phone, format: {
    with: /\A[\d\s\(\)\-\+]+\z/,
    message: "solo puede contener números, espacios, paréntesis y guiones"
  }, allow_blank: true
  
  # Dirección
  validates :address, length: { maximum: 500 }, allow_blank: true
  validates :city, length: { maximum: 100 }, allow_blank: true
  validates :state, length: { maximum: 50 }, allow_blank: true
  validates :state, inclusion: { 
    in: MEXICAN_STATES,
    message: "%{value} no es un estado válido de México"
  }, allow_blank: true
  
  # Código postal (5 dígitos en México)
  validates :postal_code, length: { is: 5 }, allow_blank: true
  validates :postal_code, format: {
    with: /\A\d{5}\z/,
    message: "debe ser 5 dígitos numéricos"
  }, allow_blank: true
  
  # Multi-tenant
  validates :subdomain, length: { in: 3..50 }, allow_blank: true
  validates :subdomain, format: { 
    with: /\A[a-z0-9][a-z0-9\-]*[a-z0-9]\z/,
    message: "solo letras minúsculas, números y guiones (no al inicio/fin)"
  }, allow_blank: true
  validates :subdomain, exclusion: { 
    in: %w[www admin api app support help docs blog about contact dashboard],
    message: "está reservado"
  }, allow_blank: true
  validates :subdomain, uniqueness: { case_sensitive: false }, allow_blank: true
  
  # Plan
  validates :plan, presence: true, inclusion: { in: PLANS }
  
  # Facturación (opcional)
  validates :tax_regime, length: { maximum: 100 }, allow_blank: true
  validates :cfdi_use, length: { maximum: 50 }, allow_blank: true
  
  # ==================== SCOPES ====================
  
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_plan, ->(plan) { where(plan: plan) }
  
  # ==================== MÉTODOS DE CLASE ====================
  
  # Singleton para single-tenant
  def self.current
    first_or_create! do |company|
      company.business_name = "Tienda 1"
      company.active = true
      company.plan = 'free'
    end
  end
  
  # ==================== MÉTODOS DE INSTANCIA ====================
  
  # Nombre para mostrar (con fallback seguro)
  def display_name
    business_name.presence || "Tienda ##{id}"
  end
  
  # Dirección formateada para tickets
  def full_address
    return nil if address.blank? && city.blank?
    
    parts = []
    parts << address if address.present?
    
    location_parts = [city, state].compact
    parts << location_parts.join(", ") if location_parts.any?
    
    parts << postal_code if postal_code.present?
    
    parts.join("\n")
  end
  
  # Verificar si está mínimamente configurado
  def configured?
    business_name.present? && 
    phone.present? && 
    address.present?
  end
  
  # Verificar si puede facturar
  def can_invoice?
    rfc.present? && 
    legal_name.present? && 
    tax_regime.present? && 
    cfdi_use.present? &&
    full_address.present?
  end
  
  # Info para tickets (sanitizada)
  def ticket_info
    {
      name: display_name,
      rfc: rfc&.upcase,
      phone: phone,
      email: email,
      address: full_address
    }
  end
  
  # Normalizar campos (llamar explícitamente antes de guardar)
  def normalize_attributes!
    # Limpiar y normalizar campos
    self.rfc = rfc&.upcase&.strip&.gsub(/\s+/, '') if rfc.present?
    self.email = email&.downcase&.strip if email.present?
    self.phone = phone&.strip if phone.present?
    self.subdomain = subdomain&.downcase&.strip if subdomain.present?
    self.postal_code = postal_code&.strip if postal_code.present?
    
    # Limpiar strings vacíos a nil
    self.legal_name = nil if legal_name.blank?
    self.rfc = nil if rfc.blank?
    self.email = nil if email.blank?
    self.phone = nil if phone.blank?
    self.address = nil if address.blank?
    self.city = nil if city.blank?
    self.state = nil if state.blank?
    self.postal_code = nil if postal_code.blank?
    self.subdomain = nil if subdomain.blank?
    self.tax_regime = nil if tax_regime.blank?
    self.cfdi_use = nil if cfdi_use.blank?
    
    self
  end
end