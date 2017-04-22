module Gravel
  class APNS
    class Notification
      # This class can be used to localize part of a notification.
      # You can set a notification's title, subtitle or body attribute
      # to an instance of this class to localize it.
      #
      class Localization
        # The localization key as defined in your app's localization file.
        #
        # @return [String] The localization key.
        #
        attr_reader :key

        # Additional arguments to pass into the localizable string.
        #
        # @return [Array] Additional arguments.
        #
        attr_accessor :arguments

        # Create a new localization.
        #
        # @param key [String] The localization key.
        # @param args [Splat] Arguments to pass into the localizable string.
        # @return [Gravel::APNS::Notification::Localization] The localization object.
        #
        def initialize(key, *args)
          unless key.is_a?(String)
            raise 'The localization key must be a string.'
          end

          @key = key.to_s
          self.arguments = args
        end

        # Set additional arguments to pass into the localizable string.
        #
        # @param arguments [Array] Additional arguments.
        # @return [Array] The input value.
        #
        def arguments=(arguments)
          unless arguments.nil?
            unless arguments.is_a?(Array)
              raise 'The localization arguments must be an array.'
            end

            unless arguments.all? { |a| a.is_a?(Float) || a.is_a?(Integer) || a.is_a?(String) }
              raise 'The localization arguments must all be primitives.'
            end
          end

          @arguments = arguments
        end

        # Check if there are any additional arguments.
        #
        # @return [Boolean] Whether or not there are any additional arguments.
        #
        def arguments?
          self.arguments && self.arguments.any?
        end

        # Convert the localization into APNS payload components.
        #
        # @param type [Symbol] The localization type (title/subtitle/body).
        # @return [Hash] The APNS payload components.
        #
        def payload(type)
          components = Hash.new

          case type
          when :title
            components['title-loc-key'] = @key
            components['title-loc-args'] = self.arguments if arguments?
          when :subtitle
            components['subtitle-loc-key'] = @key
            components['subtitle-loc-args'] = self.arguments if arguments?
          when :body
            components['loc-key'] = @key
            components['loc-args'] = self.arguments if arguments?
          end

          components
        end
      end
    end
  end
end
