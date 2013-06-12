# Cloud Foundry Java Buildpack
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'java_buildpack/buildpack'

module JavaBuildpack

  APP_DIR = 'test-app-dir'.freeze

  describe Buildpack do

    let(:buildpack) { Buildpack.new(APP_DIR) }
    let(:stub_container1) { double('StubContainer1') }
    let(:stub_container2) { double('StubContainer2') }
    let(:stub_jre1) { double('StubJre1', :detect => 'stub-jre-1') }
    let(:stub_jre2) { double('StubJre2', :detect => 'stub-jre-2') }
    let(:configuration) { double('SystemProperties') }

     it 'should raise an error if more than one container can run an application' do
      YAML.stub(:load_file).with(File.expand_path('config/components.yml'))
        .and_return('containers' => ['Test::StubContainer1', 'Test::StubContainer2'], 'jres' => ['Test::StubJre1'])
      SystemProperties.stub(:new).with(APP_DIR).and_return(configuration)
      Test::StubContainer1.stub(:new).and_return(stub_container1)
      Test::StubContainer2.stub(:new).and_return(stub_container2)
      Test::StubJre1.stub(:new).and_return(stub_jre1)
      stub_container1.stub(:detect).and_return('stub-container-1')
      stub_container2.stub(:detect).and_return('stub-container-2')

      expect { buildpack.detect }.to raise_error(/stub-container-1, stub-container-2/)
    end

    it 'should return no detections if no container can run an application' do
      YAML.stub(:load_file).with(File.expand_path('config/components.yml'))
        .and_return('containers' => ['Test::StubContainer1'], 'jres' => ['Test::StubJre1'])
      SystemProperties.stub(:new).with(APP_DIR).and_return(configuration)
      Test::StubContainer1.stub(:new).and_return(stub_container1)
      Test::StubJre1.stub(:new).and_return(stub_jre1)
      stub_container1.stub(:detect).and_return(nil)

      detected = buildpack.detect
      expect(detected).to be_empty
    end

    it 'should raise an error if more than one JRE can run an application' do
      YAML.stub(:load_file).with(File.expand_path('config/components.yml'))
        .and_return('containers' => ['Test::StubContainer1'], 'jres' => ['Test::StubJre1', 'Test::StubJre2'])
      SystemProperties.stub(:new).with(APP_DIR).and_return(configuration)
      Test::StubContainer1.stub(:new).and_return(stub_container1)
      Test::StubJre1.stub(:new).and_return(stub_jre1)
      Test::StubJre2.stub(:new).and_return(stub_jre2)
      stub_jre1.stub(:detect).and_return('stub-jre-1')
      stub_jre2.stub(:detect).and_return('stub-jre-2')

      expect { buildpack.detect }.to raise_error(/stub-jre-1, stub-jre-2/)
    end

    it 'should call compile on matched components' do
      YAML.stub(:load_file).with(File.expand_path('config/components.yml'))
        .and_return('containers' => ['Test::StubContainer1', 'Test::StubContainer2'], 'jres' => ['Test::StubJre1'])
      SystemProperties.stub(:new).with(APP_DIR).and_return(configuration)
      Test::StubContainer1.stub(:new).and_return(stub_container1)
      Test::StubContainer2.stub(:new).and_return(stub_container2)
      Test::StubJre1.stub(:new).and_return(stub_jre1)
      stub_container1.stub(:detect).and_return('stub-container-1')
      stub_container2.stub(:detect).and_return(nil)

      stub_jre1.should_receive(:compile)
      stub_container1.should_receive(:compile)
      stub_container2.should_not_receive(:compile)

      detected = buildpack.compile
    end

    it 'should call release on matched components' do
      YAML.stub(:load_file).with(File.expand_path('config/components.yml'))
        .and_return('containers' => ['Test::StubContainer1', 'Test::StubContainer2'], 'jres' => ['Test::StubJre1'])
      SystemProperties.stub(:new).with(APP_DIR).and_return(configuration)
      Test::StubContainer1.stub(:new).and_return(stub_container1)
      Test::StubContainer2.stub(:new).and_return(stub_container2)
      Test::StubJre1.stub(:new).and_return(stub_jre1)
      stub_container1.stub(:detect).and_return('stub-container-1')
      stub_container1.stub(:release).and_return('test-command')
      stub_container2.stub(:detect).and_return(nil)

      stub_jre1.should_receive(:release)
      stub_container2.should_not_receive(:release)

      payload = buildpack.release

      expect(payload).to eq({'addons' => [], 'config_vars' => {}, 'default_process_types' => { 'web' => 'test-command' }}.to_yaml)
    end
  end

end

module Test
  class StubContainer1
  end

  class StubContainer2
  end

  class StubJre1
  end

  class StubJre2
  end
end