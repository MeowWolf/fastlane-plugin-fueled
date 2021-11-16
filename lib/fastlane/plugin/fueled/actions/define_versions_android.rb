require_relative '../helper/fueled_helper'

module Fastlane
  module Actions
    module SharedValues
      SHORT_VERSION_STRING = :SHORT_VERSION_STRING
      BUILD_NUMBER = :BUILD_NUMBER
    end

    class DefineVersionsAndroidAction < Action
      def self.run(params)
        # Build Number
        Actions.lane_context[SharedValues::BUILD_NUMBER] = Helper::FueledHelper.new_build_number
        # Short Version
        current_short_version = Helper::FueledHelper.short_version_from_tag
        if current_short_version.split('.').first.to_i >= 1
          UI.important("Not bumping short version as it is higher or equal to 1.0.0")
          Actions.lane_context[SharedValues::SHORT_VERSION_STRING] = current_short_version
          return
        end
        new_version_number = Helper::FueledHelper.bump_semver(
          semver: current_short_version,
          bump_type: params[:bump_type]
        )
        Actions.lane_context[SharedValues::SHORT_VERSION_STRING] = new_version_number
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Sets the new build version name and build number as shared values."
      end

      def self.details
        "
        This action sets shared values for build number (SharedValues::BUILD_NUMBER) and build version name (SharedValues::SHORT_VERSION_STRING).
        Your Fastfile should use these values in a next step to set them to the project accordingly (set_app_versions_android or set_app_versions_android).
        "
      end

      def self.available_options
        verify_block = lambda do |value|
          allowed_values = ["major", "minor", "patch", "none"]
          UI.user_error!("Invalid bump type : #{value}. Allowed values are #{allowed_values.join(', ')}.") unless allowed_values.include?(value)
        end
        [
          FastlaneCore::ConfigItem.new(
            key: :bump_type,
            env_name: "VERSION_BUMP_TYPE",
            description: "The version to bump (major, minor, patch, or none)",
            optional: false,
            default_value: "none",
            verify_block: verify_block
          )
        ]
      end

      def self.output
        [
          ['SHORT_VERSION_STRING', 'The short version that should be set'],
          ['BUILD_NUMBER', 'The new build number that should be set']
        ]
      end

      def self.authors
        ["fueled"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
