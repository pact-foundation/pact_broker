require 'lib/semver/runner'

describe XSemVer::Runner do
  
  
  
  
  before :each do
    
    # Output to a file that doesn't conflict with the project's .semver file.
    @test_file = 'semver_test_file'
    XSemVer::SemVer.stub(:file_name).and_return @test_file
    
    # Capture the output that would typically appear in the console.
    @original_stdout = $stdout
    @output = StringIO.new
    $stdout = @output
    
  end
  
  after :each do
    
    # Delete the semver_test_file if one was created.
    FileUtils.rm_rf @test_file
    
    # Return output to its original value.
    $stdout = @original_stdout
    
  end
  
  
  
  
  #######################
  # SEMVER INIT(IALIZE) #
  #######################
  
  %w( init initialize ).each do |command|
    
    describe command do
    
      describe "when no .semver file exists" do
      
        it "creates a new .semver file" do
          expect {
            described_class.new command
          }.to change{ File.exist?(@test_file) }.from(false).to(true)
          v = SemVer.find
          v.major.should eq(0)
          v.minor.should eq(0)
          v.patch.should eq(0)
        end
      
      end
    
      describe "when a .semver file already exists" do
        
        before :each do
          FileUtils.touch @test_file
        end
        
        it "outputs a warning messagae" do
          described_class.new command
          @output.string.should eq("#{@test_file} already exists" + "\n")
        end
      
        it "does not overwrite the existing file" do
          expect {
            described_class.new command
          }.to_not change{ File.mtime(@test_file) }
        end
      
      end
    
    end
    
  end




  ######################
  # SEMVER INC(REMENT) #
  ######################
  
  %w( inc increment ).each do |command|
    
    describe command do
      
      before :each do
        SemVer.new(5,6,7,'foo','bar').save @test_file
      end
    
      describe "major" do
      
        it "increments the major version" do
          expect {
            described_class.new command, 'major'
          }.to change{ SemVer.find.major }.by(1)
        end
      
        it "sets the minor version to 0" do
          expect {
            described_class.new command, 'major'
          }.to change{ SemVer.find.minor }.to(0)
        end
      
        it "sets the patch vesion to 0" do
          expect {
            described_class.new command, 'major'
          }.to change{ SemVer.find.patch }.to(0)
        end
        
        it "sets the prerelease to an empty string" do
          expect {
            described_class.new command, 'major'
          }.to change{ SemVer.find.prerelease }.to('')
        end

        it "sets the metadata to an empty string" do
          expect {
            described_class.new command, 'major'
          }.to change{ SemVer.find.metadata }.to('')
        end
      
      end
    
      describe "minor" do
      
        it "does not change the major version" do
          expect {
            described_class.new command, 'minor'
          }.to_not change{ SemVer.find.major }
        end
      
        it "increments the minor version" do
          expect {
            described_class.new command, 'minor'
          }.to change{ SemVer.find.minor }.by(1)
        end
      
        it "sets the patch version to 0" do
          expect {
            described_class.new command, 'minor'
          }.to change{ SemVer.find.patch }.to(0)
        end
      
        it "sets the prerelease to an empty string" do
          expect {
            described_class.new command, 'minor'
          }.to change{ SemVer.find.prerelease }.to('')
        end

        it "sets the metadata to an empty string" do
          expect {
            described_class.new command, 'minor'
          }.to change{ SemVer.find.metadata }.to('')
        end
      
      end
    
      describe "patch" do
      
        it "does not change the major version" do
          expect {
            described_class.new command, 'patch'
          }.to_not change{ SemVer.find.major }
        end
      
        it "does not change the minor version" do
          expect {
            described_class.new command, 'patch'
          }.to_not change{ SemVer.find.minor }
        end
      
        it "increments the patch version" do
          expect {
            described_class.new command, 'patch'
          }.to change{ SemVer.find.patch }.by(1)
        end
      
        it "sets the prerelease to an empty string" do
          expect {
            described_class.new command, 'patch'
          }.to change{ SemVer.find.prerelease }.to('')
        end

        it "sets the metadata to an empty string" do
          expect {
            described_class.new command, 'patch'
          }.to change{ SemVer.find.metadata }.to('')
        end
      
      end
    
      describe "without a valid subcommand" do
        
        before :each do
          @invalid_command = 'invalid'
        end
      
        it "raises an exception" do
          expect {
            described_class.new command, @invalid_command
          }.to raise_error(
            XSemVer::Runner::CommandError,
            "#{@invalid_command} is invalid: major | minor | patch"
          )
        end
        
        it "does not modify the .semver file" do
          expect {
            begin
              described_class.new command, @invalid_command
            rescue
            end
          }.to_not change{ File.mtime(@test_file) }
        end
      
      end
      
      describe "without a subcommand" do
      
        it "raises an exception" do
          expect {
            described_class.new command
          }.to raise_error(
            XSemVer::Runner::CommandError,
            "required: major | minor | patch"
          )
        end
        
        it "does not modify the .semver file" do
          expect {
            begin
              described_class.new command
            rescue
            end
          }.to_not change{ File.mtime(@test_file) }
        end
      
      end
    
    end
  
  end
  
  
  

  #######################
  # SEMVER PRE(RELEASE) #
  #######################
    
  %w( spe special pre prerelease ).each do |command|
    
    describe command do
      
      before :each do
        SemVer.new.save @test_file
      end
    
      describe "when a string argument is provided" do
      
        it "sets the pre-release of the SemVer" do
          prerelease = 'alpha'
          expect {
            described_class.new command, prerelease
          }.to change{ SemVer.find.prerelease }.to(prerelease)
        end
      
      end
    
      describe "without a string argument" do
      
        it "raises an exception" do
          expect {
            described_class.new command
          }.to raise_error(
            XSemVer::Runner::CommandError,
            "required: an arbitrary string (beta, alfa, romeo, etc)"
          )
        end
        
        it "does not modify the .semver file" do
          expect {
            begin
              described_class.new command
            rescue
            end
          }.to_not change{ File.mtime(@test_file) }
        end

      end
    
    end
  
  end
  
  
  
  
  #####################
  # SEMVER META(DATA) #
  #####################
    
  %w( meta metadata ).each do |command|
    
    describe command do
      
      before :each do
        SemVer.new.save @test_file
      end
    
      describe "when a string argument is provided" do
      
        it "sets the metadata of the SemVer" do
          metadata = 'md5:q1w2e3r4t5'
          expect {
            described_class.new command, metadata
          }.to change{ SemVer.find.metadata }.to(metadata)
        end
      
      end
    
      describe "without a string argument" do
      
        it "raises an exception" do
          expect {
            described_class.new command
          }.to raise_error(
            XSemVer::Runner::CommandError,
            "required: an arbitrary string (beta, alfa, romeo, etc)"
          )
        end
        
        it "does not modify the .semver file" do
          expect {
            begin
              described_class.new command
            rescue
            end
          }.to_not change{ File.mtime(@test_file) }
        end

      end
    
    end
  
  end
  
  
  

  #################
  # SEMVER FORMAT #
  #################

  describe "format" do
    
    describe "without a format argument" do
      
      it "raises an exception" do
        SemVer.new.save @test_file
        expect {
          described_class.new 'format'
        }.to raise_error(
          XSemVer::Runner::CommandError,
          "required: format string"
        )
      end
      
    end
    
  end
  
  
  
  
  ##############
  # SEMVER TAG #
  ##############

  describe "tag" do
    
    it "outputs the SemVer with default formatting" do
      SemVer.new(5,6,7,'foo','bar').save @test_file
      described_class.new 'tag'
      @output.string.should eq("v5.6.7-foo+bar" + "\n")
    end
    
  end
  
  describe "with no command" do
    
    it "outputs the SemVer with default formatting" do
      SemVer.new(5,6,7,'foo','bar').save @test_file
      described_class.new
      @output.string.should eq("v5.6.7-foo+bar" + "\n")
    end
    
  end
  
  
  
  
  ###############
  # SEMVER HELP #
  ###############

  describe "help" do
    
    it "outputs instructions for using the semvar commands" do
      stubbed_help_text = 'stubbed help text'
      described_class.any_instance.stub(:help_text).and_return(stubbed_help_text)
      described_class.new 'help'
      @output.string.should eq(stubbed_help_text + "\n")
    end
    
  end
  
  
  
  
  ####################
  # INVALID COMMANDS #
  ####################

  describe "invalid commands" do
    
    it "raises an exception" do
      invalid_command = 'foo'
      expect {
        described_class.new invalid_command
      }.to raise_error(
        XSemVer::Runner::CommandError,
        "invalid command #{invalid_command}"
      )
    end
    
  end
  
  
  
  
end