require 'yaml'
require_relative './semvermissingerror'
require_relative './pre_release'

module XSemVer
# sometimes a library that you are using has already put the class
# 'SemVer' in global scope. Too Bad®. Use this symbol instead.
  class SemVer
    FILE_NAME = '.semver'
    TAG_FORMAT = 'v%M%m%p%s%d'

    def SemVer.file_name
      FILE_NAME
    end

    def SemVer.find dir=nil
      v = SemVer.new
      f = SemVer.find_file dir
      v.load f
      v
    end

    def SemVer.find_file dir=nil
      dir ||= Dir.pwd
      raise "#{dir} is not a directory" unless File.directory? dir
      path = File.join dir, file_name

      Dir.chdir dir do
        while !File.exists? path do
          raise SemVerMissingError, "#{dir} is not semantic versioned", caller if File.dirname(path).match(/(\w:\/|\/)$/i)
          path = File.join File.dirname(path), ".."
          path = File.expand_path File.join(path, file_name)
          puts "semver: looking at #{path}"
        end
        return path
      end

    end

    attr_accessor :major, :minor, :patch, :special, :metadata

    def initialize major=0, minor=0, patch=0, special='', metadata=''
      major.kind_of? Integer or raise "invalid major: #{major}"

      unless special.empty?
        special =~ /[A-Za-z][0-9A-Za-z\.]+/ or raise "invalid special: #{special}"
      end

      unless metadata.empty?
        metadata =~ /\A[A-Za-z0-9][0-9A-Za-z\.-]*\z/ or raise "invalid metadata: #{metadata}"
      end

      @major, @minor, @patch, @special, @metadata = major, minor, patch, special, metadata
    end

    def load file
      @file = file
      hash = YAML.load_file(file) || {}
      @major = hash[:major] or raise "invalid semver file: #{file}"
      @minor = hash[:minor] or raise "invalid semver file: #{file}"
      @patch = hash[:patch] or raise "invalid semver file: #{file}"
      @special = hash[:special] or raise "invalid semver file: #{file}"
      @metadata = hash[:metadata] || ""
    end

    def save file=nil
      file ||= @file

      hash = {
        :major => @major,
        :minor => @minor,
        :patch => @patch,
        :special => @special,
        :metadata => @metadata
      }

      yaml = YAML.dump hash
      open(file, 'w') { |io| io.write yaml }
    end

    def format fmt
      fmt = fmt.gsub '%M', @major.to_s
      fmt = fmt.gsub('%m', @minor ? ".#{@minor}" : '')
      fmt = fmt.gsub('%p', @patch ? ".#{@patch}" : '')
      fmt = fmt.gsub('%s', prerelease? ? "-#{@special}" : '')
      fmt = fmt.gsub('%d', metadata? ? "+#{@metadata}" : '')
      fmt
    end

    def to_s
      format TAG_FORMAT
    end

    # Compare version numbers according to SemVer 2.0.0-rc2
    def <=> other
      [:major, :minor, :patch].each do |method|
        left = send(method) || 0
        right = other.send(method) || 0
        comparison = left <=> right
        return comparison unless comparison == 0
      end
      PreRelease.new(prerelease) <=> PreRelease.new(other.prerelease)
    end

    include Comparable

    # Parses a semver from a string and format.
    def self.parse(version_string, format = nil, allow_missing = true)
      # check if git SHA
      return nil if !version_string.include?('.') && version_string.length >= 40

      format ||= TAG_FORMAT
      regex_str = Regexp.escape format

      # Convert all the format characters to named capture groups
      regex_str = regex_str.
        gsub(/^v/, 'v?').
        gsub('%M', '(?<major>\d+)').
        gsub('%m', '(?:\.(?<minor>\d+))?').
        gsub('%p', '(?:\.(?<patch>\d+))?').
        gsub('%s', '(?:-(?<special>[A-Za-z][0-9A-Za-z\.]+))?').
        gsub('%d', '(?:\\\+(?<metadata>[0-9A-Za-z][0-9A-Za-z\.]*))?')

      regex = Regexp.new(regex_str)
      match = regex.match version_string
      if match
        major = minor = patch = nil
        special = metadata = ''

        # Extract out the version parts
        major = match[:major].to_i if match.names.include? 'major'
        minor = match[:minor].to_i if match.names.include?('minor') && match[:minor]
        patch = match[:patch].to_i if match.names.include?('patch') && match[:patch]
        special = match[:special] || '' if match.names.include? 'special'
        metadata = match[:metadata] || '' if match.names.include? 'metadata'

        # Failed parse if major, minor, or patch wasn't found
        # and allow_missing is false
        return nil if !allow_missing and !major

        # Otherwise, allow them to default to zero
        major ||= 0

        SemVer.new major, minor, patch, special, metadata
      end
    end

    # Parses a rubygems string, such as 'v2.0.5.rc.3' or '2.0.5.rc.3' to 'v2.0.5-rc.3'
    def self.parse_rubygems version_string
      if /v?(?<major>\d+)
           (\.(?<minor>\d+)
            (\.(?<patch>\d+)
             (\.(?<pre>[A-Za-z]+\.[0-9A-Za-z]+) 
           )?)?)?
          /x =~ version_string

        major = major.to_i
        minor = minor.to_i if minor
        minor ||= 0
        patch = patch.to_i if patch
        patch ||= 0
        pre ||= ''
        SemVer.new major, minor, patch, pre, ''
      else
        SemVer.new
      end
    end

    # SemVer specification 2.0.0-rc2 states that anything after the '-' character is prerelease data.
    # To be consistent with the specification verbage, #prerelease returns the same value as #special.
    # TODO: Deprecate #special in favor of #prerelease?
    def prerelease
      special
    end

    # SemVer specification 2.0.0-rc2 states that anything after the '-' character is prerelease data.
    # To be consistent with the specification verbage, #prerelease= sets the same value as #special.
    # TODO: Deprecate #special= in favor of #prerelease=?
    def prerelease=(pre)
      self.special = pre
    end

    # Return true if the SemVer has a non-empty #prerelease value. Otherwise, false.
    def prerelease?
      !special.nil? && special.length > 0
    end

    # Return true if the SemVer has a non-empty #metadata value. Otherwise, false.
    def metadata?
      !metadata.nil? && metadata.length > 0
    end
  end
end
