#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'omnibus/build_version'
require 'spec_helper'

describe Omnibus::BuildVersion do

  let(:git_describe){ "11.0.0-alpha1-207-g694b062" }
  let(:valid_semver_regex){/^\d+\.\d+\.\d+(\-[\dA-Za-z\-\.]+)?(\+[\dA-Za-z\-\.]+)?$/}
  let(:valid_git_describe_regex){/^\d+\.\d+\.\d+(\-[A-Za-z0-9\-\.]+)?(\-\d+\-g[0-9a-f]+)?$/}
  subject(:build_version){ Omnibus::BuildVersion }

  before :each do
    # FIXME - memoized class instance variables are a code smell
    build_version.instance_variable_set(:@git_describe, nil)
    build_version.instance_variable_set(:@build_time, nil)
    build_version.stub(:git_describe).and_return(git_describe)
    ENV['BUILD_ID'] = nil
  end

  describe "build version parsing" do

    context "11.0.1" do
      let(:git_describe){ "11.0.1" }
      its(:version_tag){ should == "11.0.1" }
      its(:prerelease_tag){ should be_nil }
      its(:git_sha){ should be_nil }
      its(:commits_since_tag){ should == 0 }
      its(:development_version?){ should be_true }
      its(:prerelease_version?){ should be_false }
    end

    context "11.0.0-alpha2" do
      let(:git_describe){ "11.0.0-alpha2" }
      its(:version_tag){ should == "11.0.0" }
      its(:prerelease_tag){ should == "alpha2" }
      its(:git_sha){ should be_nil }
      its(:commits_since_tag){ should == 0 }
      its(:development_version?){ should be_false }
      its(:prerelease_version?){ should be_true }
    end

    context "11.0.0-alpha-59-gf55b180" do
      let(:git_describe){ "11.0.0-alpha-59-gf55b180" }
      its(:version_tag){ should == "11.0.0" }
      its(:prerelease_tag){ should == "alpha" }
      its(:git_sha){ should == "f55b180" }
      its(:commits_since_tag){ should == 59 }
      its(:development_version?){ should be_false }
      its(:prerelease_version?){ should be_true }
    end
  end

  describe "semver output" do
    let(:today_string){ Time.now.utc.strftime("%Y%m%d") }

    it "generates a valid semver version" do
      build_version.semver.should =~ valid_semver_regex
    end

    it "generates a version matching format 'MAJOR.MINOR.PATCH-PRERELEASE+TIMESTAMP.git.COMMITS_SINCE.GIT_SHA'" do
      build_version.semver.should =~ /11.0.0-alpha1\+#{today_string}[0-9]+.git.207.694b062/
    end

    it "uses ENV['BUILD_ID'] to generate timestamp if set" do
      ENV['BUILD_ID'] = "2012-12-25_16-41-40"
      build_version.semver.should == "11.0.0-alpha1+20121225164140.git.207.694b062"
    end

    it "fails on invalid ENV['BUILD_ID'] values" do
      ENV['BUILD_ID'] = "AAAA"
      expect { build_version.semver }.to raise_error(ArgumentError)
    end

    context "prerelease version with dashes" do
      let(:git_describe){ "11.0.0-alpha-3-207-g694b062" }

      it "converts all dashes to dots" do
        build_version.semver.should =~ /11.0.0-alpha.3\+#{today_string}[0-9]+.git.207.694b062/
      end
    end

    context "exact version" do
      let(:git_describe){ "11.0.0-alpha2" }

      it "appends a timestamp with no git info" do
        build_version.semver.should =~ /11.0.0-alpha2\+#{today_string}[0-9]+/
      end
    end
  end

  describe "git describe output" do
    it "generates a valid git describe version" do
      build_version.git_describe.should =~ valid_git_describe_regex
    end

    it "generates a version matching format 'MAJOR.MINOR.PATCH-PRELEASE.COMMITS_SINCE-gGIT_SHA'" do
      build_version.git_describe.should == git_describe
    end
  end

  describe "deprecated full output" do
    it "generates a valid git describe version" do
      build_version.full.should =~ valid_git_describe_regex
    end

    it "outputs a deprecation message" do
      build_version.should_receive(:puts).with(/is deprecated/)
      build_version.full
    end
  end
end
