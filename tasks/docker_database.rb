require 'docker'

module DockerDatabase

  POSTGRES_IMAGE_NAME = 'postgres:9.6'.freeze

  def self.start(options)
    Docker::Image.create('fromImage' => POSTGRES_IMAGE_NAME)
    host_port = options.fetch(:port)
    Docker::Container.create(
      'Image' => POSTGRES_IMAGE_NAME,
      'name' => options.fetch(:name),
      'ExposedPorts' => { '5432/tcp' => {} },
      'HostConfig' => {
        'PortBindings' => {
          '5432/tcp' => [{ 'HostPort' => host_port }]
        }
      }
    ).start({})
  end

  def self.stop_and_remove(name)
    ::Docker::Container.get(name).remove(force: true) rescue nil
  end
end
