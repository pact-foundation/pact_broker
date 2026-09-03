#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"

# git-cliff logs INFO/WARN lines to stderr regardless of TTY; run/run! capture
# stdout and stderr together, so uncontrolled logging would corrupt the
# version string and changelog body they return. "error", not "off": run!
# builds CommandError entirely from that merged output, so a genuine failure
# must still surface its ERROR-level diagnostics.
ENV["RUST_LOG"] ||= "error"

# Release automation for the pact_broker gem.
#
# Requires git, gh and git-cliff on PATH. Runnable locally as well as in CI.
class Release
  RELEASE_BRANCH = "release/pact_broker"
  BASE_BRANCH    = "master"
  VERSION_FILE   = "lib/pact_broker/version.rb"
  TAG_PREFIX     = "v"

  class CommandError < StandardError; end

  # MARK: Version file

  def self.read_version(path = VERSION_FILE)
    File.read(path)[/VERSION = "([^"]*)"/, 1] or
      raise "Could not read version from #{path}"
  end

  def self.write_version(version, path = VERSION_FILE)
    content = File.read(path)
    updated = content.sub(/VERSION = "[^"]*"/, %(VERSION = "#{version}"))
    raise "Could not find version to update in #{path}" if updated == content

    File.write(path, updated)
  end

  # MARK: Version computation

  # git-cliff prints the bumped tag, e.g. "v2.121.0". Returns nil when there is
  # nothing to release: cliff printed nothing, repeated the current version
  # (every commit since the last tag was skipped, such as chore(deps)), or
  # failed and printed a message.
  def self.normalise_bumped_version(cliff_output, current)
    version = cliff_output.to_s.strip.delete_prefix(TAG_PREFIX)
    return nil unless version.match?(/\A\d+\.\d+\.\d+\z/)
    return nil if version == current

    version
  end

  def self.increment_between(previous, current)
    return "patch" if previous.nil?

    was = previous.split(".").map(&:to_i)
    now = current.split(".").map(&:to_i)
    return "major" if now[0] != was[0]
    return "minor" if now[1] != was[1]

    "patch"
  end

  # MARK: Command runners

  def self.run!(*cmd)
    out, status = Open3.capture2e(*cmd)
    raise CommandError, "Command failed: #{cmd.join(' ')}\n#{out}" unless status.success?

    out.strip
  end

  # Runs a command whose failure is an expected outcome, returning its combined
  # output. Callers inspect the output rather than a status.
  def self.run(*cmd)
    out, = Open3.capture2e(*cmd)
    out.strip
  end

  # MARK: git-cliff

  def self.next_version(current)
    normalise_bumped_version(run!("git", "cliff", "--bumped-version"), current)
  end

  def self.changelog_entry(tag)
    run!("git", "cliff", "--tag", tag, "--unreleased", "--strip", "header")
  end

  def self.prepend_changelog(tag)
    run!("git", "cliff", "--tag", tag, "--unreleased", "--prepend", "CHANGELOG.md")
  end

  def self.previous_tag
    tags = run("git", "tag", "--list", "#{TAG_PREFIX}*", "--sort=-version:refname").lines.map(&:strip)
    tags.reject!(&:empty?)
    tags.find { |candidate| candidate != "#{TAG_PREFIX}#{read_version}" }
  end

  # MARK: Subcommands

  def self.prepare(dry_run:)
    current = read_version
    bumped  = next_version(current)

    if bumped.nil?
      puts "No releasable commits since v#{current} — nothing to do."
      return
    end

    tag = "#{TAG_PREFIX}#{bumped}"
    puts "Preparing release #{tag} (current version #{current})..."

    write_version(bumped)
    prepend_changelog(tag)
    body = changelog_entry(tag)

    if dry_run
      puts "--dry-run: leaving #{VERSION_FILE} and CHANGELOG.md modified in the working tree."
      puts
      puts body
      return
    end

    run!("git", "checkout", "-B", RELEASE_BRANCH, "origin/#{BASE_BRANCH}")
    run!("git", "add", VERSION_FILE, "CHANGELOG.md")
    run!("git", "commit", "-m", "chore: prepare release #{tag}")
    run!("git", "push", "--force", "origin", RELEASE_BRANCH)

    upsert_release_pr(tag, body)
  ensure
    run("git", "checkout", BASE_BRANCH) unless dry_run
  end

  def self.upsert_release_pr(tag, body)
    existing = run!("gh", "pr", "list", "--head", RELEASE_BRANCH, "--state", "open",
                    "--json", "number", "--jq", ".[0].number")

    if existing.empty? || existing == "null"
      run!("gh", "pr", "create", "--draft", "--base", BASE_BRANCH, "--head", RELEASE_BRANCH,
           "--title", "chore: release #{tag}", "--body", body)
      puts "Created draft release PR for #{tag}"
    else
      run!("gh", "pr", "edit", existing, "--title", "chore: release #{tag}", "--body", body)
      puts "Updated release PR ##{existing} for #{tag}"
    end
  end

  def self.tag_release
    tag = "#{TAG_PREFIX}#{read_version}"

    run!("git", "fetch", "--tags", "origin")
    unless run("git", "tag", "--list", tag).empty?
      puts "Tag #{tag} already exists — nothing to do."
      return
    end

    run!("git", "tag", tag)
    run!("git", "push", "origin", tag)
    puts "Pushed tag #{tag}"
  end

  def self.print_increment
    puts increment_between(previous_tag&.delete_prefix(TAG_PREFIX), read_version)
  end

  # MARK: CLI

  USAGE = "Usage: script/release.rb prepare [--dry-run] | tag | increment"

  def self.parse_args(argv)
    command = argv[0]
    flags   = argv[1..] || []
    raise ArgumentError, USAGE unless %w[prepare tag increment].include?(command)

    dry_run = flags.delete("--dry-run") ? true : false
    raise ArgumentError, USAGE unless flags.empty?
    raise ArgumentError, "--dry-run is only supported by prepare. #{USAGE}" if dry_run && command != "prepare"

    [command.to_sym, dry_run]
  end
end

if __FILE__ == $PROGRAM_NAME
  begin
    command, dry_run = Release.parse_args(ARGV)
  rescue ArgumentError => e
    warn e.message
    exit 1
  end

  case command
  when :prepare   then Release.prepare(dry_run: dry_run)
  when :tag       then Release.tag_release
  when :increment then Release.print_increment
  end
end
