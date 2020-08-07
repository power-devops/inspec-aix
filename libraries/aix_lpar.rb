class AixLpar < Inspec.resource(1)
  name 'aix_lpar'
  supports platform: 'aix'
  desc 'AIX LPAR information'
  example <<~EOX
    describe aix_lpar do
      its('node_name') { should cmp 'lpar' }
      its('lpar_name') { should cmp 'lpar' }
      its('mode') { should cmp 'Capped' }
    end
  EOX

  def initialize
    @params = {}
    @cmd = 'lparstat -i'
    @result ||= inspec.backend.run_command(@cmd)
    if @result.exit_status.to_i != 0
      raise Inspec::Exceptions::ResourceFailed,
        'Error executing lparstat -i'
    end

    @result.stdout.split("\n").each do |l|
      p, v = l.split(':')
      p = p.strip.downcase.gsub(/ /, '_')
      v.strip!
      @params[p] = v
    end
  end

  def method_missing(name)
    @params[name.to_s]
  end
end
