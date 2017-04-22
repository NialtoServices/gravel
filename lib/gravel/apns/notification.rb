module Gravel
  class APNS
    # A notification for an Apple device (using APNS).
    #
    class Notification
      PRIORITY_IMMEDIATE = 10
      PRIORITY_ECO = 5

      # The title of the notification.
      # You can provide a localization on this value.
      #
      # @return [String|Gravel::APNS::Notification::Localization] The title.
      #
      attr_accessor :title

      # The subtitle of the notification.
      # You can provide a localization on this value.
      #
      # @return [String|Gravel::APNS::Notification::Localization] The subtitle.
      #
      attr_accessor :subtitle

      # The body of the notification.
      # You can provide a localization on this value.
      #
      # @return [String|Gravel::APNS::Notification::Localization] The body.
      #
      attr_accessor :body

      # The name of the sound file to play when notifying the user.
      #
      # @return [String] The sound file name.
      #
      attr_accessor :sound

      # The badge number to show on the application icon.
      #
      # @return [Integer] The badge number.
      #
      attr_accessor :badge

      # A localization key to use when populating the content of the 'View' button.
      #
      # @param [String] The action button's localization key.
      #
      attr_accessor :action_key

      # A category to identify the notification's type.
      # This should match one of the identifier values as defined in your
      # application.
      #
      # @param [String] The notification's category.
      #
      attr_accessor :category

      # The filename of an image to use when launching the app.
      #
      # @param [String] The launch image filename.
      #
      attr_accessor :launch_image

      # Set to true to trigger a silent notification in your application.
      # This is useful to trigger a background app refresh.
      #
      # @return [Boolean] Whether or not new content is available.
      #
      attr_accessor :content_available

      # The mutable content of the notification.
      #
      # @return [Hash] The mutable content.
      #
      attr_accessor :mutable_content

      # A unique identifier for this notification.
      #
      # @return [String] The unique identifier.
      #
      attr_accessor :uuid

      # A group identifier for the notification.
      # This allows APNS to identify similar messages and collapse them
      # into a single notification.
      #
      # @return [String] The collapse identifier.
      #
      attr_accessor :collapse_id

      # The priority of the notification.
      #
      # @return [Integer] The priority.
      #
      attr_accessor :priority

      # A time when the notification is no longer valid and APNS should stop
      # attempting to deliver the notification.
      #
      # @return [Time] The expiration time.
      #
      attr_accessor :expiration

      # A token representing the device you want to send the notification to.
      #
      # @return [String] The device token.
      #
      attr_accessor :device_token

      # Create a new APNS notification.
      #
      # @return [Gravel::APNS::Notification] The notification object.
      #
      def initialize
        self.content_available = false
        self.uuid = SecureRandom.uuid
      end

      # Generate the APNS payload.
      #
      # @return [Hash] The APNS payload.
      #
      def payload
        aps = Hash.new

        if self.title.is_a?(String)
          aps['alert'] ||= Hash.new
          aps['alert']['title'] = self.title
        elsif self.title.is_a?(Gravel::APNS::Notification::Localization)
          aps['alert'] ||= Hash.new
          aps['alert'].merge!(self.title.payload(:title))
        end

        if self.subtitle.is_a?(String)
          aps['alert'] ||= Hash.new
          aps['alert']['subtitle'] = self.subtitle
        elsif self.subtitle.is_a?(Gravel::APNS::Notification::Localization)
          aps['alert'] ||= Hash.new
          aps['alert'].merge!(self.subtitle.payload(:subtitle))
        end

        if self.body.is_a?(String)
          aps['alert'] ||= Hash.new
          aps['alert']['body'] = self.body
        elsif self.body.is_a?(Gravel::APNS::Notification::Localization)
          aps['alert'] ||= Hash.new
          aps['alert'].merge!(self.body.payload(:body))
        end

        if self.sound == :default
          aps['sound'] = 'default'
        elsif self.sound.is_a?(String)
          aps['sound'] = self.sound.to_s
        end

        if self.badge.is_a?(Integer)
          aps['badge'] = self.badge
        end

        if self.action_key.is_a?(String)
          aps['alert']['action-loc-key'] = self.action_key
        end

        if self.category.is_a?(String)
          aps['category'] = self.category
        end

        if self.launch_image.is_a?(String)
          aps['alert']['launch-image'] = self.launch_image
        end

        if self.content_available
          aps['content-available'] = '1'
        end

        payload = Hash.new

        if self.mutable_content.is_a?(Hash)
          aps['mutable-content'] = '1'
          payload.merge!(self.mutable_content)
        end

        unless aps.empty?
          payload['aps'] = aps
        end

        payload
      end
    end
  end
end
