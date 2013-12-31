# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: François Charlier <francois.charlier@enovance.com>
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

require 'json'

Puppet::Type.type(:mongo_replset).provide(:mongo) do

  # commands :mongo => 'mongo'

  def create
    hostsconf = @resource[:members].collect.with_index do |host, id|
      "{ _id: #{id}, host: \"#{host}\" }"
    end.join(',')
    conf = "{ _id: \"#{@resource[:name]}\", members: [ #{hostsconf} ] }"
    output = mongo("rs.initiate(#{conf})")
    output['ok'] == 1
  end

  def destroy
  end

  def exists?
    begin
      #FIXME: should raise an error if the replicaset name doesn't match
      is_replicaset? and is_configured?
    rescue Puppet::ExecutionFailure
      debug "Does't exist"
      false
    end
  end

  def members
    mongo('db.isMaster()')['hosts']
  end

  def members=(hosts)
    current = mongo('db.isMaster()')['hosts']
    newhosts = hosts - current
    newhosts.each do |host|
      mongo("rs.add(\"#{host}\")")
    end
  end



  private

  def _mongo(command_str)
    debug("Running mongo command: #{command_str}")
    open('| mongo --quiet 2>&1', 'w+') do |pipe|
      pipe.write(command_str)
      pipe.close_write
      out = pipe.read
      debug("Mongo command: #{command_str} output:\n#{out}")
      out
    end
  end

  def mongo(command)
    command_str = command.respond_to?(:join) ? command.join(' ') : command
    output = _mongo(command_str)

    # Allow waiting up to 30 seconds for mongod to become ready
    # Wait for 2 seconds initially, double time at each iteration
    wait = 2
    while output =~ /Error: couldn't connect to server/ and wait <= 16
      info("Waiting #{wait} seconds for mongod to become available")
      sleep wait
      output = _mongo(command_str)
      wait *= 2
    end

    unless $CHILD_STATUS == 0
      raise Puppet::ExecutionFailure, output
    end

    # Dirty hack to remove JavaScript objects
    output.gsub!(/ISODate\((.+?)\)/, '\1 ')
    output.gsub!(/Timestamp\((.+?)\)/, '[\1]')
    JSON.parse(output)
  end

  def is_replicaset?
    status = mongo('db.isMaster()')
    status.has_key?('isreplicaset') or status.has_key?('setName')
  end

  def is_master?(set_name)
    status = mongo('db.isMaster()')
    status.has_key?('setName') and
      status['setName'] == set_name and
      status['ismaster']
  end

  def is_configured?
    status = mongo('db.isMaster()')
    status.has_key?('setName')
  end

end
