# frozen_string_literal: true

basedir = File.expand_path('../lib', __FILE__)
libraries =
  [
    'redmine_chart_sql/utils',
  ]

libraries.each do |library|
  require_dependency File.expand_path(library, basedir)
end

Redmine::Plugin.register :redmine_chart_sql do
  name 'Redmine Chart SQL plugin'
  author '9506hqwy'
  description 'This is a chart render macro from SQL.'
  version '0.2.0'
  url 'https://github.com/9506hqwy/redmine_chart_sql'
  author_url 'https://github.com/9506hqwy'

  Redmine::WikiFormatting::Macros.register do
    desc "Run SQL to Chart"
    macro :chart_sql do |obj, args, text|
      graph = RedmineChartSql::Utils.sql_to_js(args, text)

      if (Redmine::VERSION::ARRAY <=> [5.0]) >= 0
        lib = javascript_include_tag('chart.min.js')
      elsif (Redmine::VERSION::ARRAY <=> [4.0]) >= 0
        lib = javascript_include_tag('Chart.bundle.min')
      else
        lib = javascript_include_tag('chart.min.js', plugin: :redmine_chart_sql)
      end

      id = "chart-#{Redmine::Utils.random_hex(16)}"
      width = graph[:width]
      height = graph[:heigth]
      config = graph[:config]

      graph = "
      #{lib}
      <div style=\"width: #{width}; height: #{height};\">
        <canvas id=\"#{id}\" style=\"width: 100%; height: 100%;\"></canvas>
        <script type=\"text/javascript\">
          new Chart(document.getElementById(\"#{id}\"), #{config});
        </script>
      </div>
      "

      graph.html_safe
    end
  end
end
