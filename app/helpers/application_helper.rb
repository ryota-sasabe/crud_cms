module ApplicationHelper

  def sortable(model, column, title = nil)
    title ||= column.titleize
    table_column = "#{model.tableize}.#{column}"
    css_class = (table_column == sort_column) ? "current #{sort_direction}" : nil
    direction = (table_column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to title, {:sort => "#{model}[#{column}]", :direction => direction}, {:class => css_class}
  end

end
