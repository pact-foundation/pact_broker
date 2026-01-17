# frozen_string_literal: true

require "bump"

namespace :bump do
  run_bump = lambda do |bump, options|
    output, status = Bump::Bump.run(bump, options)
    puts output
    abort unless status == 0
  end

  (Bump::Bump::BUMPS + ["current", "file", "show-next"]).each do |bump|
    if bump == "current"
      desc "Show current gem version"
    elsif bump == "show-next"
      desc "Show next #{Bump::Bump::BUMPS.join('|')} version."
    elsif bump == "file"
      desc "Show version file path"
    else
      desc "Bump #{bump} part of gem version"
    end

    task bump, :no_args do |_task, args|
      if args.no_args
        raise(
          RakeArgumentsDeprecatedError,
          "rake arguments are deprecated, use TAG=false to disable tagging"
        )
      end
      options = {
        tag: ENV['TAG'],
        tag_prefix: ENV['TAG_PREFIX'],
        commit: ENV['COMMIT'],
        bundle: ENV['BUNDLE'],
        increment: ENV['INCREMENT']
      }
      run_bump.call(bump, Bump::Bump.parse_cli_options!(options))
    end
  end

  desc "Sets the version number using the VERSION environment variable"
  task :set do
    run_bump.call("set", version: ENV['VERSION'])
  end
end
