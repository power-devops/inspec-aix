class AixNo < Inspec.resource(1)
  name 'aix_no'
  supports platform: 'aix'
  desc 'AIX network tunable (no)'
  example <<~EOX
    describe aix_no('tcp_keepinit') do
      its('value') { should be 150 }
    end
  EOX

  def initialize(no = nil)
    if no.nil? || no.empty?
      raise Inspec::Exceptions::ResourceFailed,
        'You must specify network tunable name'
    end

    @wert = ''
    @name = no
    @exist = false
    @cmd = "no -o #{@name}"
    @result ||= inspec.backend.run_command(@cmd)
    if @result.exit_status.to_i != 0
      @exist = false
    else
      @exist = true
      @wert = @result.stdout.split("\n")[0].split("=")[1].strip
    end
  end

  def to_s
    "aix_no(#{@name})"
  end

  def value
    @wert.to_i
  rescue
    @wert
  end
end
