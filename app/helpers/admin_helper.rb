module AdminHelper

  # Render main menu item element
  def menuitem(title, path, selected)
    active = request.path.match(selected)

    content_tag :li, class: active ? 'active' : nil do
      link_to title, path
    end
  end

end
