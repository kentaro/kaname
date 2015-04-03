require 'yaml'

module Kaname
  class Resource
    DEFAULT_FILENAME = 'keystone.yml'
    class << self
      def yaml
        @_yaml = if File.exists?(DEFAULT_FILENAME)
                   YAML.load_file(DEFAULT_FILENAME)
                 else
                   nil
                 end
      end

      def user(name)
        begin
          user = Kaname::Resource.users.find_by_name(user)
          user.id
        rescue Fog::Identity::OpenStack::NotFound
          password = Kaname::Generator.password
          puts "#{user},#{password}"
          response = Fog::Identity[:openstack].create_user(user, password, h["email"])
          response.data[:body]["user"]["id"]
        end
      end

      def users
        @_users ||= Fog::Identity[:openstack].users
      end

      def tenants
        @_tenants ||= Fog::Identity[:openstack].tenants
      end

      def roles
        @_roles ||= Fog::Identity[:openstack].roles
      end

      def users_hash
        return @h if @h

        @h = {}
        users.each do |u|
          next if ignored_users.include?(u.name)
          @h[u.name] = {}
          @h[u.name]["email"] = u.email
          @h[u.name]["tenants"] = {}
          tenants.each do |t|
            r = u.roles(t.id)
            if r.size > 0
              @h[u.name]["tenants"][t.name] = r.first["name"]
            end
          end
        end
        @h
      end

      # default service users
      def ignored_users
        %w[
          neutron
          glance
          cinder
          admin
          nova_ec2
          nova
        ]
      end
    end
  end
end
