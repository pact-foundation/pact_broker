require 'json'
require 'fileutils'
require 'nokogiri'
require 'approvals/version'
require 'approvals/combination_approvals'
require 'approvals/configuration'
require 'approvals/approval'
require 'approvals/dsl'
require 'approvals/error'
require 'approvals/system_command'
require 'approvals/scrubber'
require 'approvals/dotfile'
require 'approvals/executable'
require 'approvals/reporters'
require 'approvals/filter'
require 'approvals/writer'
require 'approvals/verifier'
require 'approvals/namers/default_namer'

module Approvals
  extend DSL

  class << self

    def project_dir
      @project_dir ||= FileUtils.pwd
    end

    def reset
      Dotfile.reset
    end
  end
end

Approvals.reset
