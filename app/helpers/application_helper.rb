module ApplicationHelper
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
end