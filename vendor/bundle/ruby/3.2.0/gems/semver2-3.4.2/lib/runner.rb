require 'semver'
require 'dsl'

module XSemVer
  
  # Contains the logic for performing SemVer operations from the command line.
  class Runner
    
    include XSemVer::DSL
    
    # Run a semver command. Raise a CommandError if the command does not exist.
    # Expects an array of commands, such as ARGV.
    def initialize(*args)
      @args = args
      run_command(@args.shift || :tag)
    end
    
    private
    
    def next_param_or_error(error_message)
      @args.shift || raise(CommandError, error_message)
    end
    
    def help_text
      <<-HELP
semver commands
---------------

init[ialze]                        # initialize semantic version tracking
inc[rement] major | minor | patch  # increment a specific version number
pre[release] [STRING]              # set a pre-release version suffix
spe[cial] [STRING]                 # set a pre-release version suffix (deprecated)
meta[data] [STRING]                # set a metadata version suffix
format                             # printf like format: %M, %m, %p, %s
tag                                # equivalent to format 'v%M.%m.%p%s'
help

PLEASE READ http://semver.org
      HELP
    end
    
    
    
    
    # Create a new .semver file if the file does not exist.
    command :initialize, :init do
      file = SemVer.file_name
      if File.exist? file
        puts "#{file} already exists"
      else
        version = SemVer.new
        version.save file
      end
    end
    
    
    # Increment the major, minor, or patch of the .semver file.
    command :increment, :inc do
      version = SemVer.find
      dimension = next_param_or_error("required: major | minor | patch")
      case dimension
      when 'major'
        version.major += 1
        version.minor =  0
        version.patch =  0
      when 'minor'
        version.minor += 1
        version.patch =  0
      when 'patch'
        version.patch += 1
      else
        raise CommandError, "#{dimension} is invalid: major | minor | patch"
      end
      version.special = ''
      version.metadata = ''
      version.save
    end
    
    
    # Set the pre-release of the .semver file.
    command :special, :spe, :prerelease, :pre do
      version = SemVer.find
      version.special = next_param_or_error("required: an arbitrary string (beta, alfa, romeo, etc)")
      version.save
    end
    
    
    # Set the metadata of the .semver file.
    command :metadata, :meta do
      version = SemVer.find
      version.metadata = next_param_or_error("required: an arbitrary string (beta, alfa, romeo, etc)")
      version.save
    end
    
        
    # Output the semver as specified by a format string.
    # See: SemVer#format
    command :format do
      version = SemVer.find
      puts version.format(next_param_or_error("required: format string"))
    end
    
    
    # Output the semver with the default formatting.
    # See: SemVer#to_s
    command :tag do
      version = SemVer.find
      puts version.to_s
    end
    
    
    # Output instructions for using the semvar command.
    command :help do
      puts help_text
    end
    



  end
  
end