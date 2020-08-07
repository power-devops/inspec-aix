class AixDevice < Inspec.resource(1)
  name 'aix_device'
  supports platform: 'aix'
  desc 'AIX device attributes'
  example <<~EOX
    describe aix_device('sys0') do
      its('fullcore') { should cmp 'false' }
      its('maxuproc') { should cmp '4096' }
    end
  EOX

  def initialize(dev = nil)
    if dev.nil?
      raise Inspec::Exceptions::ResourceFailed,
        'You must specify device name'
    end

    @params = {}
    @dev = dev 
    @cmd = "lsattr -El #{dev} -F attribute:value"
    @result ||= inspec.backend.run_command(@cmd)
    if @result.exit_status.to_i != 0
      raise Inspec::Exceptions::ResourceFailed,
        "Error executing lsattr -El #{dev}"
    end

    @result.stdout.split("\n").each do |l|
      p, v = l.split(':')
      @params[p] = v
    end
  end

  def to_s
    "aix_device(#{@dev})"
  end

  def method_missing(name)
    @params[name.to_s]
  rescue
    nil
  end
end
