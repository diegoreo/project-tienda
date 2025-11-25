class ReportPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  # Reportes de ventas
  def sales_report?
    supervisor? # Supervisor o superior
  end

  # Reporte de ventas detallado (con costos)
  def detailed_sales_report?
    accountant? # Contador, Gerente o Admin
  end

  # Reporte de inventario
  def inventory_report?
    warehouse? # Almacenista o superior
  end

  # Reporte de cartera (clientes con deuda)
  def portfolio_report?
    accountant? # Contador, Gerente o Admin
  end

  # Reporte de caja
  def cash_report?
    supervisor? # Supervisor o superior
  end

  # Reporte de utilidades
  def profit_report?
    accountant? # Contador, Gerente o Admin
  end

  # Reporte de productos más vendidos
  def top_products_report?
    supervisor? # Supervisor o superior
  end

  # Reporte de ventas por vendedor
  def sales_by_user_report?
    supervisor? # Supervisor o superior
  end

  # Reportes gerenciales (completos)
  def management_reports?
    manager? # Solo Gerente o Admin
  end
end
