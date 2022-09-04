# Redmine Chart SQL

This plugin provides a chart graph rendering by using SQL.

## Features

- Render chart graph using `Chart.js`.
- Customize chart graph using sql comment.
- Macro arguments is sql placeholder.

## Installation

1. Download plugin in Redmine plugin directory.
   ```sh
   git clone https://github.com/9506hqwy/redmine_chart_sql.git
   ```
2. Start Redmine

## Customization

The sql comment is `config` in `Chart` class constructor.

This format is `-- KEY: VALUE`.
`KEY` is dotted string, ex) `config.type`.
`VALUE` is value, ex) 1, true, "rgb(0, 0, 0)".

The bellow key is special keyword.

- `config.data.label_column`: specify column name to use as label (default: database column name)
- `height`: specify image height (default; 50vh)
- `width`: specify image width (default: 50vw)

see bellow examples.

## Examples

- Summation spent time per day in version `1.0.0`

```
{{chart_sql(1.0.0)
-- config.data.label_column: "spent_on"

SELECT time_entries.spent_on, sum(time_entries.hours)
FROM time_entries
JOIN issues ON time_entries.issue_id = issues.id
JOIN versions ON issues.fixed_version_id = versions.id AND versions.name = ?
GROUP BY time_entries.spent_on
ORDER BY time_entries.spent_on
}}
```

- Stack spent time per activity during `1.0.0`

```
{{chart_sql(version=1.0.0)
-- config.type: "bar"
-- config.options.scales.xAxes[0].stacked: true
-- config.options.scales.yAxes[0].stacked: true
-- config.data.datasets[0].backgroundColor: "rgb(0, 255, 0)"
-- config.data.datasets[1].backgroundColor: "rgb(0, 0, 255)"
-- config.data.label_column: "date"
-- width: "70vw"
-- height: "70vh"

SELECT
    dates.day AS date,
    (
        SELECT sum(time_entries.hours)
        FROM time_entries
        JOIN issues ON issues.id = time_entries.issue_id
        JOIN versions ON versions.id = issues.fixed_version_id AND versions.name = :version
        JOIN enumerations ON enumerations.id = time_entries.activity_id AND enumerations.name = 'Design'
        WHERE time_entries.spent_on <= dates.day
    ) AS Design,
    (
        SELECT sum(time_entries.hours)
        FROM time_entries
        JOIN issues ON issues.id = time_entries.issue_id
        JOIN versions ON versions.id = issues.fixed_version_id AND versions.name = :version
        JOIN enumerations ON enumerations.id = time_entries.activity_id AND enumerations.name = 'Development'
        WHERE time_entries.spent_on <= dates.day
    ) AS Development
FROM (SELECT DATE(d.*) AS day FROM generate_series('2022-08-01'::date, '2022-09-30', '2 day') AS d) AS dates
}}
```

## Notes

This plugin has security issues by design.
The user operations Redmine database using raw SQL.

## Tested Environment

* Redmine (Docker Image)
  * 3.4
  * 4.0
  * 4.1
  * 4.2
  * 5.0
* Database
  * SQLite
  * MySQL 5.7
  * PostgreSQL 12