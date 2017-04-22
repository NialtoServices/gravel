module Gravel
  class APNS
    # Used internally to generate JWT tokens for APNS.
    #
    class AutoToken
      # The identifier for the developer's team.
      #
      # @return [String] The team identifier.
      #
      attr_reader :team_id

      # The identifier for the APNS key.
      #
      # @return [String] The key identifier.
      #
      attr_reader :key_id

      # Create a new AutoToken instance.
      #
      # @param team_id [String] The team identifier.
      # @param key_id [String] The key identifier.
      # @param key [OpenSSL::PKey::EC] The private key.
      # @return [Gravel::APNS::AutoToken] An AutoToken instance.
      #
      def initialize(team_id, key_id, key)
        unless team_id.is_a?(String)
          raise 'The team identifier must be a string.'
        end

        unless key_id.is_a?(String)
          raise 'The key identifier must be a string.'
        end

        unless key_id.length == 10
          raise 'The key identifier does not appear to be valid.'
        end

        unless key.is_a?(OpenSSL::PKey::EC)
          raise 'The key must be an elliptic curve key.'
        end

        unless key.private_key?
          raise 'The key must contain a private key.'
        end

        @key = key
        @key_id = key_id
        @team_id = team_id
        @token_generation_mutex = Mutex.new
      end

      # Get the next token to use.
      #
      # @return [String] The next token.
      #
      def token
        if require_token_generation?
          @token_generation_mutex.synchronize do
            # Double check if we need to regenerate the token.
            # This could happen if two threads try to concurrently access
            # the token after it has expired (or before initial generation).
            if require_token_generation?
              @last_generated = time
              @token = generate_token
            end
          end
        end

        @token
      end

      # Generate a bearer token.
      #
      # @return [String] A bearer token.
      #
      def bearer_token
        'Bearer ' + token
      end

      private
      # Check if we need to generate a new token.
      #
      def require_token_generation?
        @token == nil || @last_generated == nil || @last_generated < (time - 3540)
      end

      # Generate a new token.
      #
      # @return [String] The token.
      #
      def generate_token
        headers = { 'kid' => @key_id }
        claims  = { 'iat' => Time.now.utc.to_i, 'iss' => @team_id }

        JWT.encode(claims, @key, 'ES256', headers)
      end

      # Get the current time in seconds (Epoch).
      #
      # @return [Integer] The current time in seconds.
      #
      def time
        Time.now.utc.to_i
      end
    end
  end
end
