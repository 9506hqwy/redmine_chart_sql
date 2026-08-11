# frozen_string_literal: true

module RedmineChartSql
  class ViewListener < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, partial: 'chart_sql/html_head'
  end
end
