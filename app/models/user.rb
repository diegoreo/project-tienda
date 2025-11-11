class User < ApplicationRecord

  # Relaciones con register_sessions
  has_many :opened_sessions, class_name: 'RegisterSession', foreign_key: 'opened_by_id'
  has_many :closed_sessions, class_name: 'RegisterSession', foreign_key: 'closed_by_id'
  has_many :cancelled_sales, class_name: 'Sale', foreign_key: 'cancelled_by_id'
  
  # Devise modules - SOLO lo esencial para login
  # QUITAMOS: :registerable, :recoverable (para que no puedan recuperar/cambiar password)
  devise :database_authenticatable,
         :rememberable, :validatable,
         :trackable,
         authentication_keys: [:login]
  
  # Enums para roles (6 roles del sistema POS)
  enum :role, {
    cajero: 0,        # Acceso básico: solo ventas y cobros
    supervisor: 1,    # Cajero + cancelar ventas + corte de caja + reportes del día
    almacenista: 2,   # Gestión de inventario y productos
    contador: 3,      # Solo lectura: reportes y exportaciones
    gerente: 4,       # Acceso completo excepto gestión de usuarios
    admin: 5          # Acceso total al sistema
  }
  
  # Validaciones
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :admins, -> { where(role: :admin) }
  scope :gerentes, -> { where(role: :gerente) }
  scope :contadores, -> { where(role: :contador) }
  scope :supervisores, -> { where(role: :supervisor) }
  scope :cajeros, -> { where(role: :cajero) }
  scope :almacenistas, -> { where(role: :almacenista) }

  # Atributo virtual para login
  attr_accessor :login

  # Método para encontrar usuario por email O name
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(["lower(name) = :value OR lower(email) = :value", { value: login.downcase }]).first
    elsif conditions.has_key?(:name) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end
  
  # Métodos de conveniencia para verificar roles
  def admin?
    role == 'admin'
  end
  
  def gerente?
    role == 'gerente'
  end
  
  def contador?
    role == 'contador'
  end
  
  def supervisor?
    role == 'supervisor'
  end
  
  def cajero?
    role == 'cajero'
  end
  
  def almacenista?
    role == 'almacenista'
  end
  
  # Métodos para verificar permisos por grupo
  def puede_vender?
    # Cajero, Supervisor, Gerente, Admin
    cajero? || supervisor? || gerente? || admin?
  end
  
  def puede_gestionar_inventario?
    # Almacenista, Gerente, Admin
    almacenista? || gerente? || admin?
  end
  
  def puede_cancelar_ventas?
    # Supervisor, Gerente, Admin
    supervisor? || gerente? || admin?
  end
  
  def puede_ver_reportes?
    # Todos excepto Cajero básico
    !cajero? || supervisor? || gerente? || admin? || contador?
  end
  
  def puede_gestionar_usuarios?
    # Solo Admin
    admin?
  end
  
  def puede_modificar_precios?
    # Gerente, Admin
    gerente? || admin?
  end
  
  # Método para desactivar usuario (en vez de eliminarlo)
  def deactivate!
    update(active: false)
  end
  
  def activate!
    update(active: true)
  end
  
  # Override de Devise para solo permitir login a usuarios activos
  def active_for_authentication?
    super && active?
  end
  
  # Mensaje cuando el usuario está inactivo
  def inactive_message
    active? ? super : :account_inactive
  end
  
  # Nombre del rol en español (para mostrar en UI)
  def role_name
    I18n.t("enums.user.role.#{role}")
  end
end