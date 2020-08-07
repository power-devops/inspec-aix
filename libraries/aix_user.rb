class AixUser < Inspec.resource(1)
  name 'aix_user'
  supports platform: 'aix'
  desc 'AIX user information'
  example <<~EOX
    describe aix_user('root') do
      it { should exist }
      it { should be_locked }
      its('home') { should match '/root' }
    end
  EOX

  def initialize(user = nil)
    if user.nil? || user.empty?
      raise Inspec::Exceptions::ResourceFailed,
        'You must specify user name'
    end

    @params = {}
    @name = user
    @cmd = "lsuser -c #{@name}"
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
        expires
        loginretries
        pwdwarntime
        minage
        maxage
        maxexpired
        minalpha
        minloweralpha
        minupperalpha
        minother
        mindigit
        minspecialchar
        mindiff
        maxrepeats
        minlen
        histexpire
        histsize
        fsize
        fsize_hard
        cpu
        cpu_hard
        data
        data_hard
        stack
        stack_hard
        core
        core_hard
        rss
        rss_hard
        nofiles
        nofiles_hard
        time_last_login
        time_last_unsuccessful_login
        unsuccessful_login_count
      ).each do |k|
        if @params[k].nil? || @params[k].empty?
          @params[k] = -1
        else
          @params[k] = @params[k].to_i
        end
      end
      # known bools
      # known arrays (csv)
      %w(
        groups
        sugroups
        auditclasses
        admgroups
        dictionlist
        default_roles
        roles
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

  def locked?
    return true if @params['account_locked'] == true
    if @params['loginretries'] != 0 || @params['loginretries'] != -1
      return true if @params['unsuccessful_login_count'] >= @params['loginretries']
    end
    false
  rescue
    false
  end

  def local?
    @params['registry'] == 'files' || @params['registry'] == 'KRB5files'
  rescue
    true
  end

  def to_s
    "aix_user(#{@name})"
  end

  def method_missing(name)
    @params[name.to_s]
  rescue
    nil
  end
end

class AixUsers < Inspec.resource(1)
  name 'aix_users'
  supports platform: 'aix'
  desc 'Multiple AIX users, which can be filtered'
  example <<~EOX
    describe aix_users.where { name == 'root' } do
      it { should exist }
    end
  EOX

  filter = FilterTable.create
  filter.register_custom_matcher(:exists?) { |x| !x.entries.empty? }
  filter.register_column(:names,    field: 'name')
        .register_column(:ids,      field: 'id')
  filter.install_filter_methods_on_resource(self, :collect_user_details)

  def to_s
    'AIX users'
  end

  private

  # collects information about every user
  def collect_user_details
    cmd = 'lsuser -a ALL'  # get all user names
    result ||= inspec.backend.run_command(cmd)
    return [] if result.exit_status.to_i != 0
    names = result.stdout.split("\n")
    users_cache = []
    names.sort.uniq.each do |n|
      users_cache << AixUser(inspec, n)
    end
    users_cache
  end
end
