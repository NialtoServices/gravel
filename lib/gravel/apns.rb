module Gravel
  # Manages the connection to APNS.
  # You should keep this instance somewhere instead of recreating it every
  # time you need to send notifications.
  #
  class APNS
    # The production APNS server URL.
    #
    PRODUCTION_URL = 'api.push.apple.com'

    # The development APNS server URL.
    #
    DEVELOPMENT_URL = 'api.development.push.apple.com'

    # The default APNS port.
    #
    DEFAULT_PORT = 443

    # The alternative APNS port.
    #
    ALTERNATIVE_PORT = 2197

    class << self
      # Attempt to load a key from the specified path.
      #
      # @param path [String] The path to the key file.
      # @return [OpenSSL::PKey::EC] The key.
      #
      def key_from_file(path)
        unless File.file?(path)
          raise "A key could not be loaded from: #{path}"
        end

        OpenSSL::PKey::EC.new(File.read(path))
      end
    end

    # The topic to pass to APNS.
    # This is usually the bundle identifier of the application you're sending
    # push notifications to.
    #
    # @return [String] The APNS topic.
    #
    attr_reader :topic

    # Create a new APNS instance.
    #
    # @param alternative_port [Boolean] (optional) Should we use the default (443) or the alternative (2197) port?
    # @param concurrency [Integer] (optional) How many connections to APNS should we open?
    # @param environment [Symbol] (optional) :production or :development
    # @param key [OpenSSL::PKey::EC] An elliptic curve key (APNS authentication).
    # @param key_id [String] The key's identifier.
    # @param team_id [String] The team's identifier.
    # @param topic [String] The topic to pass to APNS.
    # @return [Gravel::APNS] An APNS instance.
    #
    def initialize(options = {})
      options = {
        alternative_port: false,
        concurrency: 1,
        environment: :development
      }.merge(options)

      unless options[:topic].is_a?(String)
        raise 'The APNS topic is required.'
      end

      unless [true, false].include?(options[:alternative_port])
        raise 'The alternative port should be a boolean value.'
      end

      unless options[:concurrency].is_a?(Integer) && options[:concurrency] > 0
        raise 'Concurrency should be specified as an Integer greater than zero.'
      end

      unless [:development, :production].include?(options[:environment])
        raise 'The environment should be either :production or :development.'
      end

      host = case options[:environment]
      when :development
        DEVELOPMENT_URL
      when :production
        PRODUCTION_URL
      end

      port = options[:alternative_port] ? ALTERNATIVE_PORT : DEFAULT_PORT

      @auto_token = Gravel::APNS::AutoToken.new(options[:team_id], options[:key_id], options[:key])
      @queue = Queue.new
      @topic = options[:topic]
      @url = "https://#{host}:#{port}"

      @workers = options[:concurrency].times.map do
        client = NetHttp2::Client.new(@url)

        thread = Thread.new(client) do |client|
          Thread.current.abort_on_exception = true

          loop do
            Thread.current[:processing] = false

            notification, block = @queue.pop

            Thread.current[:processing] = true

            process_notification(notification, client, &block)
          end
        end

        { client: client, thread: thread }
      end
    end

    # The identifier for the developer's team.
    #
    # @return [String] The team's identifier.
    #
    def team_id
      @auto_token.team_id
    end

    # The identifier for the APNS key.
    #
    # @return [String] The key's identifier.
    #
    def key_id
      @auto_token.key_id
    end

    # Push a notification onto the send queue.
    #
    # @param notification [Gravel::APNS::Notification] The notification to send.
    # @param block [Proc] The block to call when the request has completed.
    # @return [Boolean] Whether or not the notification was sent.
    #
    def send(notification, &block)
      if @workers.nil? || @workers.empty?
        raise "There aren't any workers to process this notification!"
      end

      @queue.push([notification, block])

      nil
    end

    # Wait for all threads to finish processing.
    #
    def wait
      threads = @workers.map { |w| w[:thread] }

      until @queue.empty? && threads.all? { |t| t[:processing] == false }
        # Waiting for the threads to finish ...
      end
    end

    # Close all clients and terminate all workers.
    #
    def close
      @queue.clear

      if @workers.is_a?(Array)
        @workers.each do |payload|
          payload[:thread].kill
          payload[:client].close
        end

        @workers = nil
      end

      nil
    end

    private
    # Process a notification (in a worker).
    #
    # @param notification [Gravel::APNS::Notification] The notification to process.
    # @param client [NetHttp2::Client] The client to use.
    # @param block [Proc] The block to call on completion.
    #
    def process_notification(notification, client, &block)
      unless notification.is_a?(Gravel::APNS::Notification)
        raise 'The notification must be an instance of Gravel::APNS::Notification.'
      end

      unless client.is_a?(NetHttp2::Client)
        raise 'The client must be an instance of NetHttp2::Client.'
      end

      unless notification.device_token
        block.call(false) if block_given?
        return
      end

      path = "/3/device/#{notification.device_token}"

      headers = Hash.new
      headers['authorization'] = @auto_token.bearer_token
      headers['apns-topic'] = @topic

      if notification.uuid
        headers['apns-id'] = notification.uuid
      end

      if notification.collapse_id
        headers['apns-collapse-id'] = notification.collapse_id
      end

      if notification.priority
        headers['apns-priority'] = notification.priority.to_s
      end

      if notification.expiration && notification.expiration.is_a?(Time)
        headers['apns-expiration'] = notification.expiration.utc.to_i.to_s
      end

      body = notification.payload.to_json

      response = client.call(:post, path, headers: headers, body: body)

      block.call(response.ok?, response) if block_given?
    end
  end
end
