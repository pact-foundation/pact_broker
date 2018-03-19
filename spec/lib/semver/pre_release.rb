require 'lib/semver/semver'


describe XSemVer::PreRelease do
  subject(:pre_releases) { strings.map { |s| described_class.new s } }

  context 'with semver.org v2.0.0 section 10 example data' do
    let(:strings) { ["alpha", "alpha.1", "alpha.beta", "beta", "beta.2", "beta.11", "rc.1", ""] }

    it 'should remain the same after a sort' do
      pre_releases.sort.each_with_index do |pr, i|
        strings[i].should eq(pr.to_s)
      end
    end

    it 'should remain the same after a reverse and sort' do
      pre_releases.reverse.sort.each_with_index do |pr, i|
        strings[i].should eq(pr.to_s)
      end
    end
  end
end

