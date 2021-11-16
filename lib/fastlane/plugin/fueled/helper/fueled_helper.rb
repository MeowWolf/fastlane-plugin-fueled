require 'fastlane/action'
require 'fastlane_core/ui/ui'
require 'fastlane/plugin/versioning'
require 'fastlane/plugin/appcenter'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class FueledHelper
      # Returns the new build number, by bumping the last git tag build number.
      def self.new_build_number
        last_tag = Actions::LastGitTagAction.run(pattern: nil) || "v0.0.0#0-None"
        last_build_number = (last_tag[/#(.*?)-/m, 1] || "0").to_i
        last_build_number + 1
      end

      # Returns the current short version. If the major version in the project or
      # plist is equal or greater than 1, it will be returned. Otherwise, the version
      # returned will be the one identified in the last git tag.
      def self.short_version_ios(project_path:)
        version = Actions::GetVersionNumberFromPlistAction.run(
          xcodeproj: project_path,
          target: nil,
          scheme: nil,
          build_configuration_name: nil
        )
        UI.important("No short version found in plist, looking in Xcodeproj...") if version.nil?
        if version.nil?
          version = Actions::GetVersionNumberFromXcodeprojAction.run(
            xcodeproj: project_path,
            target: nil,
            scheme: nil,
            build_configuration_name: nil
          )
        end
        UI.important("No short version found in the project, will rely on git tags to find out the last short version.") if version.nil?
        if !version.nil? && version.split('.').first.to_i >= 1
          version
        else
          short_version_from_tag
        end
      end

      # Returns the current short version, only by reading the last tag.
      def self.short_version_from_tag
        last_tag = Actions::LastGitTagAction.run(pattern: nil) || "v0.0.0#0-None"
        last_tag[/v(.*?)[(#]/m, 1]
      end

      # Bump a given semver version, by incrementing the appropriate
      # component, as per the bump_type (patch, minor, major, or none).
      def self.bump_semver(semver:, bump_type:)
        splitted_version = {
            major: semver.split('.').map(&:to_i)[0] || 0,
            minor: semver.split('.').map(&:to_i)[1] || 0,
            patch: semver.split('.').map(&:to_i)[2] || 0
          }
        case bump_type
        when "patch"
          splitted_version[:patch] = splitted_version[:patch] + 1
        when "minor"
          splitted_version[:minor] = splitted_version[:minor] + 1
          splitted_version[:patch] = 0
        when "major"
          splitted_version[:major] = splitted_version[:major] + 1
          splitted_version[:minor] = 0
          splitted_version[:patch] = 0
        end
        [splitted_version[:major], splitted_version[:minor], splitted_version[:patch]].map(&:to_s).join('.')
      end

      # Returns the default artefact file depending on the platform (ios vs android).
      # This function is being used by the upload_to_app_center and the
      # create_github_release actions.
      def self.default_output_file
        platform = Actions.lane_context[Actions::SharedValues::PLATFORM_NAME].to_s
        if platform == "ios"
          Actions.lane_context[Actions::SharedValues::IPA_OUTPUT_PATH]
        elsif platform == "android" && ENV['BUILD_FORMAT'] == "apk"
          Actions.lane_context[Actions::SharedValues::GRADLE_APK_OUTPUT_PATH]
        elsif platform == "android"
          Actions.lane_context[Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH]
        end
      end
    end
  end
end
