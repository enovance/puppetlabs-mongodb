#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

require 'spec_helper'

describe Puppet::Type.type(:mongo_replset).provider(:mongo) do

  let(:resource) { Puppet::Type.type(:mongo_replset).new(
    { :ensure        => :present,
      :name          => 'test',
      :members       => ['mongo1:27017', 'mongo2:27017'],
      :provider      => described_class.name
    }
  )}

  let(:provider) { resource.provider }

  describe 'create' do
    it 'creates a replicatset' do
      provider.expects(:mongo)
      provider.create
    end
  end

  describe 'exists?' do
    it 'checks if replicaset exists' do
      provider.expects(:mongo)
      provider.exists?.should be_true
    end
  end

  describe 'members' do
    it 'returns master host for the replicaset' do
      provider.expects(:mongo)
      provider.members.should be_true
    end
  end

  describe 'members=' do
    it 'changes the master host of the replicaset' do
      provider.members=("mongo2:27017")
    end
  end

end
