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

  desc "Manage hosts members for a replicaset."

  #commands :mongo => 'mongo'

  def create
    hostsconf = @resource[:members].collect.with_index do |host, id|
      "{ _id: #{id}, host: \"#{host}\" }"
    end.join(',')
    conf = "{ _id: \"#{@resource[:name]}\", members: [ #{hostsconf} ] }"
    output = mongo("rs.initiate(#{conf})", @resource[:members][0])
    if output['ok'] == 0
      raise Puppet::Error, "rs.initiate() failed for replicaset #{@resource[:name]}: #{output['errmsg']}"
    end
  end

  def destroy
  end

  def exists?
    failcount = 0
    is_configured = false
    @resource[:members].each do |host|
      begin
        debug "Checking replicaset member #{host} ..."
        status = mongo('rs.status()', host)
        if status.has_key?('errmsg') and status['errmsg'] == 'not running with --replSet'
            raise Puppet::Error, "Can't configure replicaset #{@resource[:name]}, host #{host} is not supposed to be part of a replicaset."
        end
        if status.has_key?('set')
          if status['set'] != @resource[:name]
            raise Puppet::Error, "Can't configure replicaset #{@resource[:name]}, host #{host} is already part of another replicaset."
          end
          is_configured = true
        end
      rescue Puppet::ExecutionFailure
        debug "Can't connect to replicaset member #{host}."
        failcount += 1
      end
    end

    if failcount == @resource[:members].length
      raise Puppet::Error, "Can't connect to any member of replicaset #{@resource[:name]}."
    end
    return is_configured
  end

  def members
    if master = master_host()
      mongo('db.isMaster()', master)['hosts']
    else
      raise Puppet::Error, "Can't find master host for replicaset #{@resource[:name]}."
    end
  end

  def members=(hosts)
    if master = master_host()
      current = mongo('db.isMaster()', master)['hosts']
      newhosts = hosts - current
      newhosts.each do |host|
        mongo("rs.add(\"#{host}\")", master)
    end
    else
      raise Puppet::Error, "Can't find master host for replicaset #{@resource[:name]}."
    end
  end

  private

  def _mongo(command_str, host)
    debug("Running mongo command: #{command_str}")
    open("| mongo #{host} --quiet 2>&1", 'w+') do |pipe|
      pipe.write(command_str)
      pipe.close_write
      out = pipe.read
      debug("Mongo command: #{command_str} output:\n#{out}")
      out
    end
  end

  def mongo(command, host)
    command_str = command.respond_to?(:join) ? command.join(' ') : command
    output = _mongo(command_str, host)

    # Allow waiting up to 30 seconds for mongod to become ready
    # Wait for 2 seconds initially, double time at each iteration
    wait = 2
    while output =~ /Error: couldn't connect to server/ and wait <= 16
      info("Waiting #{wait} seconds for mongod to become available")
      sleep wait
      output = _mongo(command_str, host)
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

  def master_host
    @resource[:members].each do |host|
      status = mongo('db.isMaster()', host)
      if status.has_key?('primary')
        return status['primary']
      end
    end
    false
  end

end
