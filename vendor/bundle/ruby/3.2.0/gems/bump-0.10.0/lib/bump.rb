# frozen_string_literal: true

module Bump
  class InvalidIncrementError < StandardError; end
  class InvalidOptionError < StandardError; end
  class InvalidVersionError < StandardError; end
  class UnfoundVersionError < StandardError; end
  class TooManyVersionFilesError < StandardError; end
  class UnfoundVersionFileError < StandardError; end
  class RakeArgumentsDeprecatedError < StandardError; end

  class <<self
    attr_accessor :tag_by_default, :replace_in_default, :changelog
  end

  class Bump
    BUMPS         = ["major", "minor", "patch", "pre"].freeze
    PRERELEASE    = ["alpha", "beta", "rc", nil].freeze
    OPTIONS       = BUMPS | ["set", "current", "file"]
    VERSION_REGEX = /(\d+\.\d+\.\d+(?:-(?:#{PRERELEASE.compact.join('|')}))?)/.freeze

    class << self
      def defaults
        {
          tag: ::Bump.tag_by_default,
          tag_prefix: 'v',
          commit: true,
          changelog: ::Bump.changelog || false, # TODO: default to true with opt-out once it gets more stable
          bundle: File.exist?("Gemfile"),
          replace_in: ::Bump.replace_in_default || []
        }
      end

      def run(bump, options = {})
        options = defaults.merge(options)
        options[:commit] = false unless File.directory?(".git")

        case bump
        when *BUMPS
          bump_part(bump, options)
        when "set"
          raise InvalidVersionError unless options[:version]

          bump_set(options[:version], options)
        when "current"
          [current, 0]
        when "show-next"
          increment = options[:increment]
          raise InvalidIncrementError unless BUMPS.include?(increment)

          [next_version(increment), 0]
        when "file"
          [file, 0]
        else
          raise InvalidOptionError
        end
      rescue InvalidIncrementError
        ["Invalid increment. Choose between #{BUMPS.join(',')}.", 1]
      rescue InvalidOptionError
        ["Invalid option. Choose between #{OPTIONS.join(',')}.", 1]
      rescue InvalidVersionError
        ["Invalid version number given.", 1]
      rescue UnfoundVersionError
        ["Unable to find your gem version", 1]
      rescue UnfoundVersionFileError
        ["Unable to find a file with the gem version", 1]
      rescue TooManyVersionFilesError
        ["More than one version file found (#{$!.message})", 1]
      end

      def current
        current_info.first
      end

      def next_version(increment, current = Bump.current)
        current, prerelease = current.split('-')
        major, minor, patch, *other = current.split('.')
        case increment
        when "major"
          major = major.succ
          minor = 0
          patch = 0
          prerelease = nil
        when "minor"
          minor = minor.succ
          patch = 0
          prerelease = nil
        when "patch"
          patch = patch.succ
        when "pre"
          prerelease.strip! if prerelease.respond_to? :strip
          prerelease = PRERELEASE[PRERELEASE.index(prerelease).succ % PRERELEASE.length]
        else
          raise InvalidIncrementError
        end
        version = [major, minor, patch, *other].compact.join('.')
        [version, prerelease].compact.join('-')
      end

      def file
        current_info.last
      end

      def parse_cli_options!(options)
        options.each do |key, value|
          options[key] = parse_cli_options_value(value)
        end
        options.delete_if { |_key, value| value.nil? }
      end

      private

      def parse_cli_options_value(value)
        case value
        when "true" then true
        when "false" then false
        when "nil" then nil
        else
          value
        end
      end

      def bump(file, current, next_version, options)
        # bump in files that need to change
        [file, *options[:replace_in]].each do |f|
          return ["Unable to find version #{current} in #{f}", 1] unless replace f, current, next_version

          git_add f if options[:commit]
        end

        # bundle if needed
        if options[:bundle] && Dir.glob('*.gemspec').any? && under_version_control?("Gemfile.lock")
          bundler_with_clean_env do
            return ["Bundle error", 1] unless system("bundle")

            git_add "Gemfile.lock" if options[:commit]
          end
        end

        # changelog if needed
        if options[:changelog]
          log = Dir["CHANGELOG.md"].first
          return ["Did not find CHANGELOG.md", 1] unless log

          error = bump_changelog(log, next_version)
          return [error, 1] if error

          open_changelog(log) if options[:changelog] == :editor

          git_add log if options[:commit]
        end

        # commit staged changes
        commit next_version, options if options[:commit]

        # tell user the result
        [next_version, 0]
      end

      def open_changelog(log)
        editor = ENV['EDITOR'] || "vi"
        system "#{editor} #{log}"
      end

      def bundler_with_clean_env(&block)
        if defined?(Bundler)
          if Bundler.respond_to?(:with_unbundled_env)
            Bundler.with_unbundled_env(&block)
          else
            Bundler.with_clean_env(&block)
          end
        else
          yield
        end
      end

      def bump_part(increment, options)
        current, file = current_info
        next_version = next_version(increment, current)
        bump(file, current, next_version, options)
      end

      def bump_set(next_version, options)
        current, file = current_info
        bump(file, current, next_version, options)
      end

      def bump_changelog(file, current)
        parts = File.read(file).split(/(^##+.*)/) # headlines and their content
        prev_index = parts.index { |p| p =~ /(^##+.*(\d+\.\d+\.\d+(\.[a-z]+)?).*)/ } # position of previous version
        return "Unable to find previous version in CHANGELOG.md" unless prev_index

        # reuse the same style by just swapping the numbers
        new_heading = parts[prev_index].sub($2, current)
        # add current date if previous heading used that
        new_heading.sub!(/\d\d\d\d-\d\d-\d\d/, Time.now.strftime('%Y-%m-%d'))

        if prev_index < 2
          # previous version is first '##' element (no '## Next' present), add line feed after version to avoid
          # '## v1.0.1## v1.0.0'
          parts.insert prev_index - 1, new_heading + "\n"
        else
          # put our new heading underneath the "Next" heading, which should be above the last version
          parts.insert prev_index - 1, "\n" + new_heading
        end

        File.write file, parts.join("")
        nil
      end

      def commit_message(version, options)
        tag = "#{options[:tag_prefix]}#{version}"
        options[:commit_message] ? "#{tag} #{options[:commit_message]}" : tag
      end

      def commit(version, options)
        tag = "#{options[:tag_prefix]}#{version}"
        system("git", "commit", "-m", commit_message(version, options))
        system("git", "tag", "-a", "-m", "Bump to #{tag}", tag) if options[:tag]
      end

      def git_add(file)
        system("git", "add", "--update", file)
      end

      def replace(file, old, new)
        content = File.read(file)
        return unless content.sub!(old, new)

        File.write(file, content)
      end

      def current_info
        version, file = (
          version_from_version ||
          version_from_version_rb ||
          version_from_gemspec ||
          version_from_lib_rb ||
          version_from_chef ||
          raise(UnfoundVersionFileError)
        )
        raise UnfoundVersionError unless version

        [version, file]
      end

      def version_from_gemspec
        return unless file = find_version_file("*.gemspec")

        content = File.read(file)
        version = (
          content[/\.version\s*=\s*["']#{VERSION_REGEX}["']/, 1] ||
          File.read(file)[/Gem::Specification.new.+ ["']#{VERSION_REGEX}["']/, 1]
        )
        return unless version

        [version, file]
      end

      def version_from_version_rb
        files = Dir.glob("lib/**/version.rb")
        files.detect do |file|
          if version_and_file = extract_version_from_file(file)
            return version_and_file
          end
        end
      end

      def version_from_version
        return unless file = find_version_file("VERSION")

        extract_version_from_file(file)
      end

      def version_from_lib_rb
        files = Dir.glob("lib/**/*.rb")
        file = files.detect do |f|
          File.read(f) =~ /^\s+VERSION = ['"](#{VERSION_REGEX})['"]/i
        end
        [Regexp.last_match(1), file] if file
      end

      def version_from_chef
        file = find_version_file("metadata.rb")
        return unless file && File.read(file) =~ /^version\s+(['"])(#{VERSION_REGEX})['"]/

        [Regexp.last_match(2), file]
      end

      def extract_version_from_file(file)
        return unless version = File.read(file)[VERSION_REGEX]

        [version, file]
      end

      def find_version_file(pattern)
        files = Dir.glob(pattern)
        case files.size
        when 0 then nil
        when 1 then files.first
        else
          raise TooManyVersionFilesError, files.join(", ")
        end
      end

      def under_version_control?(file)
        @all_files ||= `git ls-files`.split(/\r?\n/)
        @all_files.include?(file)
      end
    end
  end
end
