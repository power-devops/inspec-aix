class AixService < Inspec.resource(1)
  name 'aix_service'
  supports platform: 'aix'
  desc 'AIX service (lssrc) attributes'
  example <<~EOX
    describe aix_service('xntpd') do
      it { should be_installed }
      it { should be_running }
    end
  EOX

  def initialize(src = nil)
    if src.nil?
      raise Inspec::Exceptions::ResourceFailed,
        'You must specify service name'
    end

    @params = {}
    @name = src
    @cmd1 = "/usr/bin/lssrc -Ss #{src}"
    @result1 ||= inspec.backend.run_command(@cmd1)
    if @result1.exit_status.to_i != 0
      raise Inspec::Exceptions::ResourceFailed,
        "Error executing lssrc -Ss #{src}"
    end

    @result1.stdout.split("\n").each do |l|
      v = l.split(':')
      next if v[0].start_with?('#')
      @params['subsysname'] = v[0] unless v[0].nil?
      @params['synonym'] = v[1] unless v[1].nil?
      @params['cmdargs'] = v[2] unless v[2].nil?
      @params['path'] = v[3] unless v[3].nil?
      @params['uid'] = v[4] unless v[4].nil?
      @params['auditid'] = v[5] unless v[5].nil?
      @params['standin'] = v[6] unless v[6].nil?
      @params['standout'] = v[7] unless v[7].nil?
      @params['action'] = v[8] unless v[8].nil?
      @params['multi'] = v[9] unless v[9].nil?
      @params['contact'] = v[10] unless v[10].nil?
      @params['svrkey'] = v[11] unless v[11].nil?
      @params['svrmtype'] = v[12] unless v[12].nil?
      @params['priority'] = v[13] unless v[13].nil?
      @params['signorm'] = v[14] unless v[14].nil?
      @params['sigforce'] = v[15] unless v[15].nil?
      @params['display'] = v[16] unless v[16].nil?
      @params['waittime'] = v[17] unless v[17].nil?
      @params['grpname'] = v[18] unless v[18].nil?
    end

    @cmd2 = "/usr/bin/lssrc -s #{src}"
    @result2 ||= inspec.backend.run_command(@cmd2)
    # rc = 1 means there is no such service

    @result2.stdout.split("\n").each do |l|
      next if l.start_with?('Subsystem')
      v = l.split
      if v.length == 2
        # name status
        @params['group'] = ''
        @params['pid'] = ''
        @params['status'] = v[1] unless v[1].nil?
      elsif v.length == 3
        # name group status
        # or
        # name pid status
        if !v[2].nil? && v[2] == 'active'
          @params['group'] = ''
          @params['pid'] = v[1] unless v[1].nil?
          @params['status'] = v[2] unless v[2].nil?
        else
          @params['group'] = v[1] unless v[1].nil?
          @params['pid'] = ''
          @params['status'] = v[2] unless v[2].nil?
        end
      elsif v.length == 4
        # name group pid status
        @params['group'] = v[1] unless v[1].nil?
        @params['pid'] = v[2] unless v[2].nil?
        @params['status'] = v[3] unless v[3].nil?
      end
    end
  end

  def running?
    @params['status'] == 'active'
  end

  def installed?
    !@params['subsysname'].nil?
  end

  def to_s
    "aix_service(#{@name})"
  end

  def method_missing(name)
    @params[name.to_s]
  rescue
    nil
  end
end

