class AixOslevel < Inspec.resource(1)
  name 'aix_oslevel'
  supports platform: 'aix'
  desc 'AIX version'
  example <<~EOX
    describe aix_oslevel do
      its('version') { should cmp '7.1' }
      its('tl') { should cmp '05' }
      its('sp') { should cmp '03' }
      its('level') { should matchi /^7100-05-03/ }
    end
  EOX

  def initialize
    @params = {}
    @cmd = 'oslevel -s'
    @result ||= inspec.backend.run_command(@cmd)
    if @result.exit_status.to_i != 0
      raise Inspec::Exceptions::ResourceFailed,
        'Error executing oslevel -s'
    end
    @params['level'] = @result.stdout.split("\n")[0]
    @params['version'] = @params['level'].split('-')[0].sub(/0+$/,'').gsub(/./) { |c| c+'.' }.sub(/\.$/, '')
    @params['tl'] = @params['level'].split('-')[1]
    @params['sp'] = @params['level'].split('-')[2]
    @params['week'] = @params['level'].split('-')[3]
  end

  def method_missing(name)
    @params[name.to_s]
  end
end
