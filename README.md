# InSpec AIX

This resource pack contains AIX-specific resources to audit IBM AIX.

## Using the resource pack

Example:

```yaml
depends:
  - name: inspec-aix
    git: git@github.com:power-devops/inspec-aix.git
```

## Resources 

### aix_device

Example:

```
describe aix_device('sys0') do
  its('maxuproc') { should cmp '4096' }
end
```

### aix_emgr

Example:

```
describe aix_emgr('IV80743m9a') do
  it { should be_installed }
  its('state') { should cmp 'STABLE' }
end
```

### aix_lpar

Example:

```
describe aix_lpar do
  its('mode') { should cmp 'Capped' }
  its('desired_capacity') { should match /^2.0/ }
  its('desired_virtual_cpus') { should cmp '2' }
end
```

### aix_oslevel

Example:

```
describe aix_oslevel do
  its('level') { should match /^7200-03-01-/ }
  its('version') { should cmp "7.2" }
  its('tl') { should cmp '03' }
  its('sp') { should cmp '01' }
end
```

### aix_lvol

Example:

```
describe aix_lvol do
  its('relocatable') { should cmp "y" }
  its('interpolicy') { should cmp "m" }
end
```

### aix_package

Example:

```
describe aix_package('bos.rte') do
  it { should be_installed }
  its('checksum') { should cmp "OK" }
end
```

## License

See the file LICENSE.
