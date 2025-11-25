module ApplicationHelper
  include Pagy::Frontend
  def field_error_messages(record, field)
    return unless record.errors[field].any?

    content_tag(:div, style: "color: red; font-size: 0.9em;") do
      safe_join(
        record.errors.full_messages_for(field).map do |msg|
          content_tag(:div, msg)
        end
      )
    end
  end
  # Devuelve el nombre en español del rol
  def role_name(role)
    case role.to_s
    when "admin"
      "⭐ Admin"
    when "manager"
      "👔 Gerente"
    when "accountant"
      "📊 Contador"
    when "supervisor"
      "👨‍💼 Supervisor"
    when "warehouse"
      "📦 Almacenista"
    when "cashier"
      "👤 Cajero"
    else
      role.to_s.titleize
    end
  end

  # Devuelve las clases CSS de Tailwind para el badge del rol
  def role_badge_color(role)
    case role.to_s
    when "admin"
      "bg-purple-500 text-white"
    when "manager"
      "bg-blue-500 text-white"
    when "accountant"
      "bg-green-500 text-white"
    when "supervisor"
      "bg-yellow-500 text-white"
    when "warehouse"
      "bg-orange-500 text-white"
    when "cashier"
      "bg-red-500 text-white"
    else
      "bg-gray-500 text-white"
    end
  end

  # Devuelve un icono SVG para el rol
  def role_icon(role)
    case role.to_s
    when "admin"
      "⭐"
    when "manager"
      "👔"
    when "accountant"
      "📊"
    when "supervisor"
      "👨‍💼"
    when "warehouse"
      "📦"
    when "cashier"
      "👤"
    else
      "👥"
    end
  end
end
