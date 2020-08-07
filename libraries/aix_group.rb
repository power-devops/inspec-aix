class AixGroup < Inspec.resource(1)
  name 'aix_group'
  supports platform: 'aix'
  desc 'AIX group information'
  example <<~EOX
    describe aix_group('system') do
      it { should exist }
      its('id') { should eq 0 }
    end
  EOX

  def initialize(group = nil)
    if group.nil? || group.empty?
      raise Inspec::Exceptions::ResourceFailed,
        'You must specify group name'
    end

    @params = {}
    @name = group
    @cmd = "lsgroup -c #{@name}"
    @result ||= inspec.backend.run_command(@cmd)
    if @result.exit_status.to_i != 0
      @params['exist'] = false
    else
      @params['exist'] = true
      names = @result.stdout.split("\n")[0].split(':')
      values = @result.stdout.split("\n")[1].split(':')
      return if names.nil? || names.empty?
      return if values.nil? || values.empty?
      names.each_with_index do |name, ndx|
        name.gsub!(/^#/, '')
        @params[name] = values[ndx] unless values[ndx].nil? || values[ndx].empty?
      end
      # all strings
      @params.each_key do |k|
        @params[k] = @params[k].to_s
      end
      # known integers
      %w(
        id
      ).each do |k|
        if @params[k].nil? || @params[k].empty?
          @params[k] = -1
        else
          @params[k] = @params[k].to_i
        end
      end
      # known arrays (csv)
      %w(
        adms
        users
        projects
      ).each do |k|
        if @params[k].nil? || @params[k].empty?
          @params[k] = []
        else
          @params[k] = @params[k].split(',')
        end
      end
    end
  end

  def exist?
    @params['exist']
  end

  def to_s
    "aix_group(#{@name})"
  end

  def method_missing(name)
    @params[name.to_s]
  rescue
    nil
  end
end

class AixGroups < Inspec.resource(1)
  name 'aix_groups'
  supports platform: 'aix'
  desc 'Multiple AIX groups, which can be filtered'
  example <<~EOX
    describe aix_groups.where { name == 'system' } do
      it { should exist }
      its('users') { should include 'root' }
    end
  EOX

  filter = FilterTable.create
  filter.register_custom_matcher(:exists?) { |x| !x.entries.empty? }
  filter.register_column(:names,    field: 'name')
        .register_column(:ids,      field: 'id')
        .register_column(:gids,     field: 'gid')
        .register_column(:users,    field: 'user')
        .register_column(:members,  field: 'member')
        .register_column(:projects, field: 'project')
  filter.install_filter_methods_on_resource(self, :collect_group_details)

  def to_s
    'AIX groups'
  end

  private

  # collects information about every group
  def collect_group_details
    cmd = 'lsgroup -a ALL'  # get all group names
    result ||= inspec.backend.run_command(cmd)
    return [] if result.exit_status.to_i != 0
    names = result.stdout.split("\n")
    groups_cache = []
    names.sort.uniq.each do |n|
      groups_cache << AixGroup(inspec, n)
    end
    groups_cache
  end
end
