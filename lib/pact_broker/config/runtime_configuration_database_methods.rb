module PactBroker
  module Config
    module RuntimeConfigurationDatabaseMethods
      def database_configuration
        database_credentials
          .merge(
            encoding: 'utf8',
            sslmode: database_sslmode,
            sql_log_level: sql_log_level,
            log_warn_duration: sql_log_warn_duration,
            max_connections: database_max_connections,
            pool_timeout: database_pool_timeout,
            driver_options: driver_options
          ).compact
      end


      def postgres?
        database_credentials[:adapter] == "postgres"
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
          database_port: database_port
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
          database: uri.path.sub(/^\//, ''),
          port: uri.port&.to_i,
        }.compact
      end
      private :database_configuration_from_url
    end
  end
end
