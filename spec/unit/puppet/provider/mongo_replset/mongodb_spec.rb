#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Authors: Emilien Macchi <emilien.macchi@enovance.com>
#          Francois Charlier <francois.charlier@enovance.com>
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

  valid_conf = "{ _id: \"rs_test\", members: [ { _id: 0, host: \"mongo1:27017\" }, { _id: 1, host: \"mongo2:27017\" }, { _id: 2, host: \"mongo3:27017\" } ] }"

  valid_members = ['mongo1:27017', 'mongo2:27017', 'mongo3:27017']

  rsp_empty_cnf = {
    "ismaster"            => false,
    "secondary"           => false,
    "info"                => "can't get local.system.replset config from self or any seed (EMPTYCONFIG)",
    "isreplicaset"        => true,
    "maxBsonObjectSize"   => 16777216,
    "maxMessageSizeBytes" => 48000000,
    "localTime"           => "2014-01-10T15:57:48.642Z",
    "ok"                  => 1 }

## Not all members are up when calling initiate
# {
# 	"ok" : 0,
# 	"errmsg" : "couldn't initiate : need all members up to initiate, not ok : mongo2:27017"
# }


## Wrong replicaset name
# {
# 	"ok" : 0,
# 	"errmsg" : "couldn't initiate : nonmatching repl set name in _id field: wrong vs. rsmain"
# }

  let(:resource) { Puppet::Type.type(:mongo_replset).new(
    { :ensure        => :present,
      :name          => 'rs_test',
      :members       => valid_members,
      :provider      => :mongo
    }
  )}

  let(:provider) { resource.provider }

  # before :each do
  #   described_class.stubs(:db_ismaster).with('mongo1:27017').returns(
  #     { "setName"             => "rs_test",
  #       "ismaster"            => true,
  #       "secondary"           => false,
  #       "hosts"               => [
  #         "mongo1:27017",
  #         "mongo3:27017",
  #         "mongo2:27017"
  #       ],
  #       "primary"             => "mongo1:27017",
  #       "me"                  => "mongo1:27017",
  #       "maxBsonObjectSize"   => 16777216,
  #       "maxMessageSizeBytes" => 48000000,
  #       "localTime"           => "2014-01-10T15:15:02.030Z",
  #       "ok"                  => 1 } )
  #   described_class.stubs(:db_ismaster).with('mongo2:27017').returns(
  #     { "setName"             => "rs_test",
  #       "ismaster"            => false,
  #       "secondary"           => true,
  #       "hosts"               => [
  #         "mongo1:27017",
  #         "mongo3:27017",
  #         "mongo2:27017"
  #       ],
  #       "primary"             => "mongo1:27017",
  #       "me"                  => "mongo2:27017",
  #       "maxBsonObjectSize"   => 16777216,
  #       "maxMessageSizeBytes" => 48000000,
  #       "localTime"           => "2014-01-10T15:15:02.030Z",
  #       "ok"                  => 1 } )
  #   described_class.stubs(:db_ismaster).with('mongo3:27017').returns(
  #     { "setName"             => "rs_test",
  #       "ismaster"            => false,
  #       "secondary"           => true,
  #       "hosts"               => [
  #         "mongo1:27017",
  #         "mongo3:27017",
  #         "mongo2:27017"
  #       ],
  #       "primary"             => "mongo1:27017",
  #       "me"                  => "mongo3:27017",
  #       "maxBsonObjectSize"   => 16777216,
  #       "maxMessageSizeBytes" => 48000000,
  #       "localTime"           => "2014-01-10T15:15:02.030Z",
  #       "ok"                  => 1 } )
  #   described_class.stubs(:rs_initiate).with(valid_conf, valid_members[0]).returns(
  #     { "info" => "Config now saved locally.  Should come online in about a minute.",
  #       "ok"   => 1 } )
  #   described_class.stubs(:rs_status).with('mongo1:27017').returns(
  #    { "set"     => "rsmain",
  #      "date"    => "2014-01-10T15:20:03Z",
  #      "myState" => 1,
  #      "members" => [
  #        {
  #          "_id"               => 0,
  #          "name"              => "mongo1:27017",
  #          "health"            => 1,
  #          "state"             => 1,
  #          "stateStr"          => "PRIMARY",
  #          "uptime"            => 513,
  #          "optime"            => [1389366677, 1],
  #          "optimeDate"        => "2014-01-10T15:11:17Z",
  #          "lastHeartbeat"     => "2014-01-10T15:20:03Z",
  #          "lastHeartbeatRecv" => "2014-01-10T15:20:02Z",
  #          "pingMs"            => 0
  #        },
  #        {
  #          "_id"        => 1,
  #          "name"       => "mongo2:27017",
  #          "health"     => 1,
  #          "state"      => 2,
  #          "stateStr"   => "SECONDARY",
  #          "uptime"     => 718,
  #          "optime"     => [1389366677, 1],
  #          "optimeDate" => "2014-01-10T15:11:17Z",
  #          "self"       => true
  #        },
  #        {
  #          "_id"               => 2,
  #          "name"              => "mongo3:27017",
  #          "health"            => 1,
  #          "state"             => 2,
  #          "stateStr"          => "SECONDARY",
  #          "uptime"            => 513,
  #          "optime"            => [1389366677, 1],
  #          "optimeDate"        => "2014-01-10T15:11:17Z",
  #          "lastHeartbeat"     => "2014-01-10T15:20:03Z",
  #          "lastHeartbeatRecv" => "2014-01-10T15:20:03Z",
  #          "pingMs"            => 0,
  #          "syncingTo"         => "mongo1:27017"
  #        }
  #      ],
  #      "ok" => 1 })
  #   described_class.stubs(:rs_status).with('mongo2:27017').returns(
  #    { "set"       => "rsmain",
  #      "date"      => "2014-01-10T15:20:03Z",
  #      "myState"   => 2,
  #      "syncingTo" => "mongo1:27017",
  #      "members"   => [
  #        {
  #          "_id"               => 0,
  #          "name"              => "mongo1:27017",
  #          "health"            => 1,
  #          "state"             => 1,
  #          "stateStr"          => "PRIMARY",
  #          "uptime"            => 513,
  #          "optime"            => [1389366677, 1],
  #          "optimeDate"        => "2014-01-10T15:11:17Z",
  #          "lastHeartbeat"     => ["2014-01-10T15:20:03Z"],
  #          "lastHeartbeatRecv" => ["2014-01-10T15:20:02Z"],
  #          "pingMs"            => 0
  #        },
  #        {
  #          "_id"        => 1,
  #          "name"       => "mongo2:27017",
  #          "health"     => 1,
  #          "state"      => 2,
  #          "stateStr"   => "SECONDARY",
  #          "uptime"     => 718,
  #          "optime"     => [1389366677, 1],
  #          "optimeDate" => "2014-01-10T15:11:17Z",
  #          "self"       => true
  #        },
  #        {
  #          "_id"               => 2,
  #          "name"              => "mongo3:27017",
  #          "health"            => 1,
  #          "state"             => 2,
  #          "stateStr"          => "SECONDARY",
  #          "uptime"            => 513,
  #          "optime"            => [1389366677, 1],
  #          "optimeDate"        => "2014-01-10T15:11:17Z",
  #          "lastHeartbeat"     => "2014-01-10T15:20:03Z",
  #          "lastHeartbeatRecv" => "2014-01-10T15:20:03Z",
  #          "pingMs"            => 0,
  #          "syncingTo"         => "mongo1:27017"
  #        }
  #      ],
  #      "ok" => 1 })
  #   described_class.stubs(:rs_status).with('mongo3:27017').returns(
  #    { "set"       => "rsmain",
  #      "date"      => "2014-01-10T15:20:03Z",
  #      "myState"   => 2,
  #      "syncingTo" => "mongo1:27017",
  #      "members"   => [
  #        {
  #          "_id"               => 0,
  #          "name"              => "mongo1:27017",
  #          "health"            => 1,
  #          "state"             => 1,
  #          "stateStr"          => "PRIMARY",
  #          "uptime"            => 513,
  #          "optime"            => [1389366677, 1],
  #          "optimeDate"        => "2014-01-10T15:11:17Z",
  #          "lastHeartbeat"     => "2014-01-10T15:20:03Z",
  #          "lastHeartbeatRecv" => "2014-01-10T15:20:02Z",
  #          "pingMs"            => 0
  #        },
  #        {
  #          "_id"        => 1,
  #          "name"       => "mongo2:27017",
  #          "health"     => 1,
  #          "state"      => 2,
  #          "stateStr"   => "SECONDARY",
  #          "uptime"     => 718,
  #          "optime"     => [1389366677, 1],
  #          "optimeDate" => "2014-01-10T15:11:17Z",
  #          "self"       => true
  #        },
  #        {
  #          "_id"               => 2,
  #          "name"              => "mongo3:27017",
  #          "health"            => 1,
  #          "state"             => 2,
  #          "stateStr"          => "SECONDARY",
  #          "uptime"            => 513,
  #          "optime"            => [1389366677, 1],
  #          "optimeDate"        => "2014-01-10T15:11:17Z",
  #          "lastHeartbeat"     => "2014-01-10T15:20:03Z",
  #          "lastHeartbeatRecv" => "2014-01-10T15:20:03Z",
  #          "pingMs"            => 0,
  #          "syncingTo"         => "mongo1:27017"
  #        }
  #      ],
  #      "ok" => 1 })
  #   described_class.stubs(:rs_add).with('mongo2:27017').returns(FIXME)
  #   described_class.stubs(:rs_add).with('mongo3:27017').returns(FIXME)
  # end

  describe 'create' do
    it 'should create a replicaset' do
      provider.stubs(:mongo_command).returns(
        { "info" => "Config now saved locally.  Should come online in about a minute.",
          "ok"   => 1 } )
      provider.create
    end
  end

  describe 'exists?' do
    describe 'when the replicaset is not created' do
      it 'returns false' do
        provider.stubs(:mongo).returns(<<EOT)
{
	"startupStatus" : 3,
	"info" : "run rs.initiate(...) if not yet done for the set",
	"ok" : 0,
	"errmsg" : "can't get local.system.replset config from self or any seed (EMPTYCONFIG)"
}
EOT
        provider.exists?.should be_false
      end
    end

    describe 'when the replicaset is created' do
      it 'returns true' do
        provider.stubs(:mongo).returns(<<EOT)
{
	"set" : "rs_test",
	"date" : ISODate("2014-01-10T18:39:54Z"),
	"myState" : 1,
	"members" : [ ],
	"ok" : 1
}
EOT
        provider.exists?.should be_true
      end
    end

    describe 'when at least one member is configured with another replicaset name' do
      it 'raises an error' do
        provider.stubs(:mongo).returns(<<EOT)
{
	"set" : "rs_another",
	"date" : ISODate("2014-01-10T18:39:54Z"),
	"myState" : 1,
	"members" : [ ],
	"ok" : 1
}
EOT
        expect { provider.exists? }.to raise_error(Puppet::Error, /is already part of another replicaset\.$/)
      end
    end

    describe 'when at least one member is not running with --replSet' do
      it 'raises an error' do
        provider.stubs(:mongo).returns('{ "ok" : 0, "errmsg" : "not running with --replSet" }')
        expect { provider.exists? }.to raise_error(Puppet::Error, /is not supposed to be part of a replicaset\.$/)
      end
    end

    describe 'when no member is available' do
      it 'raises an error' do
        provider.stubs(:mongo_command).raises(Puppet::ExecutionFailure, <<EOT)
Fri Jan 10 20:20:33.995 Error: couldn't connect to server localhost:9999 at src/mongo/shell/mongo.js:147
exception: connect failed
EOT
        expect { provider.exists? }.to raise_error(Puppet::Error, "Can't connect to any member of replicaset #{resource[:name]}.")
      end
    end
  end

  describe 'members' do
    it 'returns the members of a configured replicaset ' do
      provider.stubs(:mongo).returns(<<EOT)
{
	"setName" : "rs_test",
	"ismaster" : true,
	"secondary" : false,
	"hosts" : [
		"mongo1:27017",
		"mongo2:27017",
		"mongo3:27017"
	],
	"primary" : "mongo1:27017",
	"me" : "mongo1:27017",
	"maxBsonObjectSize" : 16777216,
	"maxMessageSizeBytes" : 48000000,
	"localTime" : ISODate("2014-01-10T19:31:51.281Z"),
	"ok" : 1
}
EOT
      provider.members.should =~ valid_members
    end

    it 'raises an error when the master host is not available' do
      provider.stubs(:master_host).returns(nil)
      expect { provider.members }.to raise_error(Puppet::Error, "Can't find master host for replicaset #{resource[:name]}.")
    end

  end

  describe 'members=' do
    it 'adds missing members to an existing replicaset' do
      provider.stubs(:mongo).returns(<<EOT)
{
	"setName" : "rs_test",
	"ismaster" : true,
	"secondary" : false,
	"hosts" : [
		"mongo1:27017"
	],
	"primary" : "mongo1:27017",
	"me" : "mongo1:27017",
	"maxBsonObjectSize" : 16777216,
	"maxMessageSizeBytes" : 48000000,
	"localTime" : ISODate("2014-01-10T19:31:51.281Z"),
	"ok" : 1
}
EOT
      provider.expects('rs_add').times(2)
      provider.members=(valid_members)
    end

    it 'raises an error when the master host is not available' do
      provider.stubs(:master_host).returns(nil)
      expect { provider.members=(valid_members) }.to raise_error(Puppet::Error, "Can't find master host for replicaset #{resource[:name]}.")
    end

  end

end
