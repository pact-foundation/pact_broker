require 'tempfile'
require 'lib/semver/semver'

describe SemVer do

  it "should compare against another version versions" do
    semvers = [
      SemVer.new(0, 1, 0),
      SemVer.new(0, 1, 1),
      SemVer.new(0, 2, 0),
      SemVer.new(1, 0, 0)
    ]
    (semvers.size - 1).times do |n|
      semvers[n].should < semvers[n+1]
    end
  end

  it "should serialize to and from a file" do
    tf = Tempfile.new 'semver.spec'
    path = tf.path
    tf.close!

    v1 = SemVer.new 1,10,33
    v1.save path
    v2 = SemVer.new
    v2.load path

    v1.should == v2
  end

  API = %W[special patch minor major load save format to_s <=>].collect(&:to_sym)
  API.each { |x|
    it "should quack like a SemVer class" do
      sv = SemVer.new
      sv.should respond_to(x)
    end
  }
  
  # Semantic Versioning 2.0.0-rc.1

  it "should to_s with dash" do
    v = SemVer.new 4,5,63, 'alpha.45'
    v.to_s.should == 'v4.5.63-alpha.45'
  end
  
  it "should not to_s with dash if no special" do
    v = SemVer.new 2,5,11
    v.to_s.should == "v2.5.11"
  end
  
  it "should behave like the readme says" do
    v = SemVer.new(0,0,0)
    v.major                     # => "0"
    v.major += 1
    v.major                     # => "1"
    v.special = 'alpha.46'
    v.format "%M.%m.%p%s"       # => "1.1.0-alpha.46"
    v.to_s                      # => "v1.1.0"
  end


  # Semantic Versioning 2.0.0-rc2
  
  it "aliases #prerelease to #special" do
    v1 = SemVer.new
    v1.special = 'foo'
    v1.prerelease.should == 'foo'
    v2 = SemVer.new
    v2.prerelease = 'bar'
    v2.special.should == 'bar'
  end
  
  it "compares again another SemVer by prerelease" do
    pres = %w( alpha alpha.1 beta.2 beta.3 beta.11 rc.1 )
    semvers = pres.map do |pre|
      SemVer.new 1, 0, 0, pre
    end
    (semvers.size - 1).times do |n|
      semvers[n].should < semvers[n+1]
    end
    semvers.reverse!
    (semvers.size - 1).times do |n|
      semvers[n].should > semvers[n+1]
    end
  end
  
  it "compares a SemVer with prerelease against a SemVer without prerelease" do
    v1 = SemVer.new(1, 0, 0, 'foo')
    v2 = SemVer.new(1, 0, 0)
    v1.should < v2
    v2.should > v1
    v1.should == v1
  end
  
  describe "metadata" do
  
    it "is an empty string by default" do
      SemVer.new.metadata.should == ''
    end
    
    it "can be set when a SemVer is initialized" do
      SemVer.new(1, 2, 3, 'foo', 'bar').metadata.should == 'bar'
    end
    
    it "does not affect the comparison of two SemVers" do
      v1 = SemVer.new
      v1.metadata = 'foo.123'
      v2 = SemVer.new
      v2.metadata = 'bar.456.789'
      v1.should == v2
    end
    
    it "is parsed from a string" do
      tests = {
        'bar.234.567'     => ['v1.2.3-foo.123.456+bar.234.567'],
        'SHA.q1w2e3r4t5'  => ['v1.2.3+SHA.q1w2e3r4t5'],
      }
      tests.each do |result, args|
        SemVer.parse(*args).metadata.should == result
      end
    end
    
    it "is included in the return value from #to_s" do
      SemVer.new(1, 2, 3, 'foo', 'bar').to_s.should == "v1.2.3-foo+bar"      
    end
    
    it "replaces '%d' in the #format return value" do
      SemVer.new(1, 2, 3, 'foo', 'bar').format('%d').should == '+bar'
      SemVer.new.format('%d').should == ''
    end
    
    it "must consist of only alphanumeric characters, hypens, and dots" do
      invalid_metadatas = %w( $123 alpha+beta foo_ ~ sha:q1w2r4t5u7i8 exp[dsf] a\b\c 234(rc1) foo#bar .231 -abc )
      valid_metadatas = %w( 123-abc. sha-12345 a 5 b- 4. 1....2---foo )
      invalid_metadatas.each do |meta|
        expect {
          SemVer.new(1, 0, 0, 'foo', meta)
        }.to raise_error(RuntimeError, "invalid metadata: #{meta}")
      end
      valid_metadatas.each do |meta|
        SemVer.new(1, 0, 0, 'foo', meta)
      end      
    end
    
    it "is serialised to and from a file" do
      tf = Tempfile.new 'semver.spec'
      path = tf.path
      tf.close!
      v1 = SemVer.new
      v1.metadata = "foo.123.456"
      v1.save path
      v2 = SemVer.new
      v2.load path
      v1.metadata.should == v2.metadata
      v3 = SemVer.new
      v3.save path
      v4 = SemVer.new
      v4.load path
      v4.metadata.should == ''
    end
  end

  describe 'rubygems format' do
    { 'v2.3.1.rc.56' => SemVer.new(2, 3, 1, 'rc.56'),
      'v2.3.1'       => SemVer.new(2, 3, 1),
      'v2.3'         => SemVer.new(2, 3),
      'v2'           => SemVer.new(2),
      '2.3.1.rc.56'  => SemVer.new(2, 3, 1, 'rc.56'),
      '2.3.1'        => SemVer.new(2, 3, 1),
      '2.3'          => SemVer.new(2, 3),
      '2'            => SemVer.new(2) }.
      each do |input, expected|
        it "should parse #{input}" do
          ::SemVer.parse_rubygems(input).should eq(expected)
        end
      end
  end

end
