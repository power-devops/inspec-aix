class AixEmgr < Inspec.resource(1)
  name 'aix_emgr'
  supports platform: 'aix'
  desc 'AIX interim fixes (emgr)'
  example <<~EOX
    describe aix_emgr('102mp_fix') do
      it { should be_installed }
      its('state') { should cmp 'S' }
    end
  EOX

  def initialize(fix = nil)
    if fix.nil?
      raise Inspec::Exceptions::ResourceFailed,
        'You must specify interim fix name'
    end

    @params = {}
    @fix = fix
    @cmd = "emgr -lL #{@fix} -v3"
    @result ||= inspec.backend.run_command(@cmd)
    if @result.exit_status.to_i != 0
      @params['installed'] = false
    else
      @params['installed'] = true
      @result.stdout.split("\n").each do |l|
        next if l =~ /^+---/
        next if l =~ /^====/
        next if l =~ /^  /
        break if l =~ /^FILE NUMBER:/
        p, v = l.split(':')
        next if p.nil?
        next if v.nil?
        p = p.downcase.gsub(/ /, '_')
        v.strip!
        @params[p] = v
      end
    end
  end

  def installed?
    @params['installed']
  end

  def to_s
    "aix_emgr(#{@fix})"
  end

  def method_missing(name)
    @params[name.to_s]
  rescue
    nil
  end
end
