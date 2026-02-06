class TicketPrintingPolicy < ApplicationPolicy
  def create?
    # Cualquier usuario autenticado puede imprimir tickets
    true
  end
  
  def index?
    # Ver historial de impresiones: solo supervisores+
    user.supervisor? || user.almacenista? || user.contador? || user.gerente? || user.admin?
  end
end