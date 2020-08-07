class AixPackage < Inspec.resource(1)
  name 'aix_package'
  supports platform: 'aix'
  desc 'AIX packages'
  example <<~EOX
    describe aix_package('bos.rte') do
      it { should be_installed }
      it { should be_installp }
      it { should be_commited }
      its('version') { should match '7.2.2' }
      its('checksum') { should cmp 'OK' }
    end
  EOX

  def initialize(name = nil)
    if name.nil? || name.empty?
      raise Inspec::Exceptions::ResourceFailed,
        'You must specifiy package name'
    end

    @params = {}
    @name = name
    @cmd = "lslpp -Lqc #{@name}"
    @result ||= inspec.backend.run_command(@cmd)
    if @result.exit_status.to_i != 0
      @params['installed'] = false
    else
      @params['installed'] = true
      @result.stdout.split("\n").each do |l|
        next if l =~ /^#/
        # package name:fileset:level:state:ptf id:fix state:type:description:destination dir:
        # uninstaller:message cat:message set:message num:parent:automatic:efix locked:
        # install path:build date
        v = l.split(':')
        next if v.nil? || v.empty?
        @params['package'] = v[1]
        @params['fileset'] = v[1]
        @params['level'] = @params['version'] = v[2] 
        @params['state'] = v[3]
        @params['ptfid'] = v[4]
        @params['fix_state'] = v[5]
        @params['type'] = v[6]
        @params['description'] = v[7]
        @params['destination'] = v[8]
        @params['uninstaller'] = v[9]
        @params['message_catalog'] = v[10]
        @params['message_set'] = v[11]
        @params['message_number'] = v[12]
        @params['parent'] = v[13]
        @params['automatic'] = v[14]
        @params['locked'] = v[15]
        @params['install_path'] = v[16]
        @params['build_date'] = v[17]
      end
    end
  end

  def checksum
    lppchk = "lppchk -c #{@name}"
    result ||= inspec.backend.run_command(lppchk)
    "OK" if result.exit_status.to_i == 0
    "not OK"
  end

  def installed?
    @params['installed']
  end

  def rpm?
    @params['type'] == 'R'
  end

  def installp?
    @params['type'] == 'F' || @params['type'] == ' '
  end

  def commited?
    @params['fix_state'] == 'C' || @params['fix_state'] == 'CE'
  end

  def applied?
    @params['fix_state'] == 'A' || @params['fix_state'] == 'AE'
  end

  def method_missing(name)
    checksum if name.to_s == 'checksum'
    @params[name.to_s]
  rescue
    nil
  end

  def to_s
    "aix_package(#{@name})"
  end
end
