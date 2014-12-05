#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#

require 'puppet'
require 'puppet/type/mongodb_shard'
describe Puppet::Type.type(:mongodb_shard) do

  before :each do
    @shard = Puppet::Type.type(:mongodb_shard).new(:name => 'test')
  end

  it 'should accept a replica set name' do
    @shard[:name].should == 'test'
  end

  it 'should accept a members array' do
    @shard[:members] = ['mongo1:27017', 'mongo2:27017']
    @shard[:members].should == ['mongo1:27017', 'mongo2:27017']
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:mongodb_shard).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

end
