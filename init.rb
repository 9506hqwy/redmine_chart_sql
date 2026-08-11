# frozen_string_literal: true

basedir = File.expand_path('../lib', __FILE__)
libraries =
  [
    'redmine_chart_sql/utils',
    'redmine_chart_sql/view_listener',
  ]

libraries.each do |library|
  require_dependency File.expand_path(library, basedir)
end

Redmine::Plugin.register :redmine_chart_sql do
  name 'Redmine Chart SQL plugin'
  author '9506hqwy'
  description 'This is a chart render macro from SQL.'
  version '0.3.0'
  url 'https://github.com/9506hqwy/redmine_chart_sql'
  author_url 'https://github.com/9506hqwy'

  Redmine::WikiFormatting::Macros.register do
    desc "Run SQL to Chart"
    macro :chart_sql do |obj, args, text|
      graph = RedmineChartSql::Utils.sql_to_js(args, text)

      id = "chart-#{Redmine::Utils.random_hex(16)}"
      width = graph[:width]
      height = graph[:heigth]
      config = graph[:config]

      if (Redmine::VERSION::ARRAY <=> [7, 0, 1]) >= 0
        graph = "
        <div style=\"width: #{width}; height: #{height};\" data-controller=\"chart-sql\">
          <template data-chart-sql-target=\"config\">
            #{config}
          </template>
          <canvas id=\"#{id}\" style=\"width: 100%; height: 100%;\" data-chart-sql-target=\"canvas\"></canvas>
        </div>
        "
      else
        if (Redmine::VERSION::ARRAY <=> [7, 0]) >= 0
          # https://www.redmine.org/issues/44294
          lib = javascript_include_tag('chart.min.js', plugin: :redmine_chart_sql)
        elsif (Redmine::VERSION::ARRAY <=> [5, 0]) >= 0
          lib = javascript_include_tag('chart.min.js')
        elsif (Redmine::VERSION::ARRAY <=> [4, 0]) >= 0
          lib = javascript_include_tag('Chart.bundle.min')
        else # rubocop:disable Style/DuplicateBranch
          lib = javascript_include_tag('chart.min.js', plugin: :redmine_chart_sql)
        end

        graph = "
        #{lib}
        <div style=\"width: #{width}; height: #{height};\">
          <canvas id=\"#{id}\" style=\"width: 100%; height: 100%;\"></canvas>
          <script type=\"text/javascript\">
            new Chart(document.getElementById(\"#{id}\"), #{config});
          </script>
        </div>
        "
      end

      graph.html_safe
    end
  end
end
