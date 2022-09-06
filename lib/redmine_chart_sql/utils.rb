# frozen_string_literal: true

module RedmineChartSql
  module Utils
    def self.array_to_kwargs(array)
      args = []
      kwargs = {}
      array&.each do |item|
        if item.index('=')
          kv = item.split('=', 2)
          kwargs[kv[0].to_sym] = kv[1]
        else
          args << item
        end
      end

      kwargs.empty? ? args : kwargs
    end

    def self.create_graph_data(table, data)
      label_column = data.delete(:label_column)
      datasets = data.delete(:datasets) || []

      column_names = table.columns.map { |c| c.to_s }

      if label_column
        column_names.delete(label_column)

        column_names.each_with_index do |name, i|
          datasets[i] ||= {}
          datasets[i][:label] ||= name
          datasets[i][:data] = table.map { |row| row[name] }
        end

        labels = table.map { |row| row[label_column] }
      else
        table.each_with_index do |row, i|
          datasets[i] ||= {}
          datasets[i][:data] = column_names.map { |name| row[name] }
        end

        labels = column_names
      end

      data[:labels] ||= labels
      data[:datasets] = datasets
      data
    end

    def self.execute_sql(sql, args)
      values = array_to_kwargs(args)

      sql = sql.gsub("\\(", "(")
      sql = sql.gsub("\\)", ")")
      sql = sql.gsub("\\*", "*")
      if values.is_a?(Hash)
        sql = ActiveRecord::Base.send(
          :sanitize_sql_array,
          [sql] << values)
      else
        sql = ActiveRecord::Base.send(
          :sanitize_sql_array,
          [sql] + values)
      end

      ActiveRecord::Base.connection.exec_query(sql)
    end

    def self.kv_to_hash(kv)
      hash = {}

      kv&.each_with_object(hash) do |(key, value), hobj|
        keys = key.split('.')
        last = keys[0..-2].reduce(hobj) do |h, k|
          save_hash(h, k, {})
        end

        save_hash(last, keys[-1], option_to_array(value))
      end

      hash
    end

    def self.option_to_array(value)
      if value&.index(";")
        value.split(";").map { |c| parse_to_value(c.strip) }
      else
        parse_to_value(value)
      end
    end

    def self.parse_to_value(str)
      if str.starts_with?('"')
        str[1..-2]
      elsif ['true', 'false'].include?(str)
        str == 'true'
      else
        str.to_i
      end
    end

    def self.save_hash(hash, key, value)
      if key.index("[")
        index = key.scan(/(.+)\[(\d+)\]$/)[0]
        key0 = index[0].to_sym
        key1 = index[1].to_i
        hash[key0] ||= []
        hash[key0][key1] ||= value
      else
        hash[key.to_sym] ||= value
      end
    end

    def self.split_sql_options(text)
      options = {}
      sql = []
      sqlsets = []

      text.split("\n").map do |line|
        if line.starts_with?('-- ')
          kv = line.split(':', 2)
          key = kv[0].sub(/^--/, '').strip
          value = kv[1]&.strip
          options[key] = value
        else
          sql << line

          if line.rstrip.ends_with?(';')
            sqlsets << {
              sql: sql.join("\n"),
              options: kv_to_hash(options),
            }
            options = {}
            sql = []
          end
        end
      end

      if sql.present?
        sqlsets << {
          sql: sql.join("\n"),
          options: kv_to_hash(options),
        }
      end

      sqlsets
    end

    def self.sql_to_js(args, text)
      config = {}
      global_options = {}

      split_sql_options(text).map do |result|
        sql = result[:sql]
        graph_options = result[:options]

        if global_options.empty?
          # only first one.
          global_options = graph_options
        end

        table = execute_sql(sql, args)

        graph_config = graph_options[:config] || {}
        graph_config[:type] ||= 'line'

        data_options = graph_config.delete(:data) || {}
        graph_config[:data] = create_graph_data(table, data_options)

        if config.empty?
          config = graph_config
        else
          # only config.data.datasets.
          config[:data][:datasets] += graph_config[:data][:datasets]
        end
      end

      {
        config: config.to_json,
        width: global_options[:width] || '50vw',
        heigth: global_options[:height] || '50vh',
      }
    end
  end
end
