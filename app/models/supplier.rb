class Supplier < ApplicationRecord
  has_many :purchases, dependent: :restrict_with_exception

  # Scopes útiles para filtrado
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Validaciones de presencia
  validates :name, presence: true, uniqueness: true
  validates :name, length: { minimum: 4, message: "debe tener al menos 4 caracteres" }
  
  # Validaciones de formato
  validates :email, 
    format: { with: URI::MailTo::EMAIL_REGEXP, message: "no es un correo válido" },
    allow_blank: true,
    uniqueness: { case_sensitive: false, allow_blank: true }

  validates :rfc,
    format: { 
      with: /\A[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}\z/i,
      message: "formato inválido (debe ser RFC válido de México)"
    },
    length: { in: 12..13, message: "debe tener 12 o 13 caracteres" },
    allow_blank: true,
    uniqueness: { case_sensitive: false, allow_blank: true }

  validates :phone,
    format: { 
      with: /\A\d{10}\z/,
      message: "debe tener 10 dígitos sin espacios ni guiones"
    },
    allow_blank: true

  validates :mobile,
    format: { 
      with: /\A\d{10}\z/,
      message: "debe tener 10 dígitos sin espacios ni guiones"
    },
    allow_blank: true

  validates :zip_code,
    format: { 
      with: /\A\d{5}\z/,
      message: "debe tener 5 dígitos"
    },
    allow_blank: true
end