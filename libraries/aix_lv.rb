class AixLVol < Inspec.resource(1)
  name 'aix_lvol'
  supports platform: 'aix'
  desc 'AIX logical volume attributes'
  example <<~EOX
    describe aix_lvol('hd8') do
      its('copies') { should cmp '1' }
      its('relocatable') { should cmp 'true' }
    end
  EOX

  def initialize(vol = nil)
    if vol.nil?
      raise Inspec::Exceptions::ResourceFailed,
        'You must specify logical volume name'
    end

    @params = {}
    @name = vol
    @cmd = "/usr/sbin/getlvcb -AT #{vol}"
    @result ||= inspec.backend.run_command(@cmd)
    if @result.exit_status.to_i != 0
      raise Inspec::Exceptions::ResourceFailed,
        "Error executing getlvcb -AT #{vol}"
    end

    @result.stdout.split("\n").each do |l|
      p, v = l.split('=', 2)
      @params[p.strip] = v.strip unless p.nil? || v.nil?
    end
  end

  def to_s
    "aix_lvol(#{@name})"
  end

  def method_missing(name)
    @params[name.to_s]
  rescue
    nil
  end
end

