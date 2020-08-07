class AixFilesystem < Inspec.resource(1)
  name 'aix_fs'
  supports platform: 'aix'
  desc 'AIX filesystem attributes'
  example <<~EOX
    describe aix_fs('/home') do
      it { should exist }
      it { should be_local }
      it { should_not be_nfs }
      its('size') { should be > 100000 }
    end
  EOX

  def initialize(fsname)
    if fsname.nil? || fsname.empty?
      raise Inspec::Exceptions::ResourceFailed,
        'You must specifiy file system mount point'
    end
    @fsname = fsname
    @params = {}
    @cmd = "lsfs -c #{@fsname}"
    @result ||= inspec.backend.run_command(@cmd)
    if @result.exit_status.to_i != 0
      @params['exist'] = false
    else
      @params['exist'] = true
      @result.stdout.split("\n").each do |l|
        next if l =~ /^#/
        # mount point:device:vfs:nodename:type:size:options:automount:acct
        v = l.split(':')
        next if v.nil? || v.empty? || v[7].nil?
        @params['device'] = v[1]
        @params['vfs'] = v[2]
        @params['nodename'] = v[3]
        @params['size'] = v[5].to_i
        @params['options'] = v[6]
        @params['automount'] = v[7]
        @params['accounting'] = v[8]
      end
    end
  end

  def exist?
    @params['exist']
  end

  def nfs?
    @params['vfs'] == 'nfs'
  end

  def local?
    @params['vfs'] == 'jfs2' || @params['vfs'] == 'jfs'
  end

  def method_missing(name)
    @params[name.to_s]
  rescue
    nil
  end

  def to_s
    "aix_fs(#{@fsname})"
  end
end
