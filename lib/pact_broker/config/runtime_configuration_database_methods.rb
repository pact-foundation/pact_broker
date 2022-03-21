module PactBroker
  module Config
    module RuntimeConfigurationDatabaseMethods

      # rubocop: disable Metrics/MethodLength
      # rubocop: disable Metrics/CyclomaticComplexity
      def self.included(anyway_config)
        anyway_config.class_eval do

          attr_config(
            database_adapter: "postgres",
            database_username: nil,
            database_password: nil,
            database_name: nil,
            database_host: nil,
            database_port: nil,
            database_url: nil,
            database_sslmode: nil,
            sql_log_level: :debug,
            sql_log_warn_duration: 5,
            sql_enable_caller_logging: false,
            database_max_connections: nil,
            database_pool_timeout: 5,
            database_connect_max_retries: 0,
            auto_migrate_db: true,
            auto_migrate_db_data: true,
            allow_missing_migration_files: true,
            validate_database_connection_config: true,
            database_statement_timeout: 15,
            metrics_sql_statement_timeout: 30,
            database_connection_validation_timeout: nil
          )

          coerce_types(
            database_username: :string,
            database_password: :string
          )

          def database_configuration
            database_credentials
              .merge(
                encoding: "utf8",
                sslmode: database_sslmode,
                sql_log_level: sql_log_level,
                enable_caller_logging: sql_enable_caller_logging,
                log_warn_duration: sql_log_warn_duration,
                max_connections: database_max_connections,
                pool_timeout: database_pool_timeout,
                driver_options: driver_options,
                connect_max_retries: database_connect_max_retries,
                connection_validation_timeout: database_connection_validation_timeout
              ).compact
          end

          def database_connect_max_retries= database_connect_max_retries
            super(database_connect_max_retries&.to_i)
          end

          def sql_log_level= sql_log_level
            super(sql_log_level&.downcase&.to_sym)
          end

          def sql_log_warn_duration= sql_log_warn_duration
            super(sql_log_warn_duration&.to_f)
          end

          def database_port= database_port
            super(database_port&.to_i)
          end

          def metrics_sql_statement_timeout= metrics_sql_statement_timeout
            super(metrics_sql_statement_timeout&.to_i)
          end

          def database_connection_validation_timeout= database_connection_validation_timeout
            super(database_connection_validation_timeout&.to_i)
          end

          def postgres?
            database_credentials[:adapter] =~ /postgres/
          end
          private :postgres?

          def driver_options
            if postgres?
              { options: "-c statement_timeout=#{database_statement_timeout}s" }
            end
          end
          private :driver_options

          def database_credentials
            if database_url
              database_configuration_from_url
            else
              database_configuration_from_parts
            end
          end
          private :database_credentials

          def database_configuration_from_parts
            {
              adapter: database_adapter,
              user: database_username,
              password: database_password,
              host: database_host,
              database: database_name,
              port: database_port
            }.compact
          end
          private :database_credentials

          def database_configuration_from_url
            uri = URI(database_url)
            {
              adapter: uri.scheme,
              user: uri.user,
              password: uri.password,
              host: uri.host,
              database: uri.path.sub(/^\//, ""),
              port: uri.port&.to_i,
            }.compact
          end
          private :database_configuration_from_url
        end
      end
      # rubocop: enable Metrics/MethodLength
      # rubocop: enable Metrics/CyclomaticComplexity
    end
  end
end
