require 'spec_helper'

describe 'simp_snmpd' do

  shared_examples_for "a structured module" do
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('simp_snmpd') }
      it { is_expected.to contain_class('simp_snmpd::install').that_comes_before('Class[simp_snmpd::config]') }
      it { is_expected.to contain_class('simp_snmpd::config') }
      it { is_expected.to create_service('snmpd').with_ensure('running') }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "simp_snmp class without any parameters" do
          let(:expected) { File.read('spec/expected/default_access_usm_conf')}
          let(:params) {{ }}
          it_behaves_like "a structured module"
          it { is_expected.to_not contain_class('simp_snmpd::rsync')}
          it { is_expected.to contain_class('simp_snmpd::v3::users') }
          it { is_expected.to contain_snmp__snmpv3_user('snmp_ro') }
          it { is_expected.to contain_snmp__snmpv3_user('snmp_rw') }
          #install.pp
          it { is_expected.to contain_class('snmp').with({
            :agentaddress             => ['udp:localhost:161'],
            :ensure                   => 'present',
            :autoupgrade              => 'false',
            :service_ensure           => 'running',
            :service_enable           => 'true',
            :service_config_perms     => '0750',
            :service_config_dir_group => 'root',
            :template_snmpd_conf      => 'simp_snmpd/snmp/snmpd.conf.erb',
            :snmpd_config             => ['includeDir /etc/snmp/simp_snmpd.d','includeDir /etc/snmp/snmpd.d'],
            :trap_service_ensure      => 'stopped',
            :trap_service_enable      => 'false',
            :do_not_log_tcpwrappers   => 'no',
            :manage_client            => 'false',
            :snmpd_options            => '-LS0-66',
            :snmp_config              => ['includeFile /etc/snmp/simp_snmp.conf']
            })
          }
          it { is_expected.to_not create_group('snmp') }
          it { is_expected.to_not create_user('snmp') }
          it { is_expected.to create_package('snmpd').with_ensure('present') }
          it { is_expected.to_not contain_class('simp_snmpd::install::client') }
        end
        context "config with default params" do
          it { is_expected.to create_file('/etc/snmp/simp_snmpd.d')}
          it { is_expected.to create_file('/etc/snmp/snmpd.d')}
          it { is_expected.to create_file('/etc/snmp/snmptrapd.d')}
          it { is_expected.to contain_class('simp_snmpd::config::usm') }
          it { is_expected.to contain_class('simp_snmpd::config::agent') }
          it { is_expected.to create_file('/etc/snmp/simp_snmpd.d/agent.conf') }
          it { is_expected.to_not contain_class('simp_snmpd::config::firewall')}
          it { is_expected.to_not contain_class('simp_snmpd::config::tcpwrappers')}
          it { is_expected.to_not contain_class('simp_snmpd::config::logging')}
          it { is_expected.to contain_exec('set_snmp_perms').with_command('/usr/bin/setfacl -R -m g:snmp:r /etc/snmp  ')}
          it { is_expected.to contain_class('simp_snmpd::config::system_info') }
        end
        # Tests for config::usm and v3::users
        context "config::usm  with default params" do
          #let(:expected){ "jjunk" }
          let(:expected){ File.read('spec/expected/default_access_usm_conf')}
          it { is_expected.to contain_class('simp_snmpd::v3::users') }
          it { is_expected.to create_file('/etc/snmp/simp_snmpd.d/access_usm.conf').with_content(expected) }
          it { is_expected.to create_snmp__snmpv3_user('snmp_rw')}
          it { is_expected.to create_snmp__snmpv3_user('snmp_ro')}
        end
        context "simp_snmp class with rsync on" do
          let(:params) {{
            :rsync_dlmod     => true,
            :rsync_mibs      => true,
            :rsync_mibs_dir  => '/etc/mibs_here',
            :rsync_dlmod_dir => '/etc/dlmod_there'
          }}
          it_behaves_like "a structured module"
          it { is_expected.to contain_class('simp_snmpd::config').that_comes_before('Class[simp_snmpd::rsync]') }
          it { is_expected.to contain_exec('set_snmp_perms').with_command('/usr/bin/setfacl -R -m g:snmp:r /etc/snmp /etc/dlmod_there /etc/mibs_here')}
          it { is_expected.to contain_file('/etc/mibs_here') }
          it { is_expected.to contain_file('/etc/dlmod_there') }
        end
        context "simp_snmp class with set_system_info false" do
          let(:params) {{
            :system_info => false,
          }}
          it { is_expected.to_not contain_class('simp_snmpd::config::system_info') }
        end
        context "simp_snmp class with simp parameters set to true" do
          let(:params) {{
            :firewall    => true,
            :tcpwrappers => true,
            :syslog      => true,
            :logrotate   => true,
          }}
          it_behaves_like "a structured module"
          it { is_expected.to contain_class('simp_snmpd::config::tcpwrappers')}
          it { is_expected.to contain_class('simp_snmpd::config::firewall')}
          it { is_expected.to contain_class('simp_snmpd::config::logging')}
          it { is_expected.to create_rsyslog__rule__local('XX_snmpd')}
          it { is_expected.to create_logrotate__rule('snmpd')}
        end
        context "with default security mode set to something other than usm" do
          let(:params) {{
            :defsecuritymodel => 'tsm',
          }}
          it { is_expected.to_not contain_class('simp_snmpd::config::usm')}
          it { is_expected.to contain_notify('simp_snmpd Security Model')}
        end
        context "with manage_client set to true" do
          let(:params) {{
            :manage_client => true,
          }}
          it_behaves_like "a structured module"
          it { is_expected.to contain_class('snmp').with({
              :manage_client => 'true',
            })
          }
          it { is_expected.to contain_class('simp_snmpd::install::client')}
          it { is_expected.to contain_file('/etc/snmp/simp_snmp.conf')}
        end
        context "with group and uid set" do
          let(:params) {{
            :snmpd_gid => 9999,
            :snmpd_uid => 9999
          }}
          it { is_expected.to create_user('snmp')}
          it { is_expected.to create_group('snmp')}
        end
        context "with fips on auth type set to MD5" do
          let(:params) {{
            :fips        => true,
            :defauthtype => 'MD5',
          }}
          it {is_expected.to compile.and_raise_error(/Invalid default authentication type/)}
        end
        context "with fips on priv type set to DES" do
          let(:params) {{
            :fips        => true,
            :defauthtype => 'SHA',
            :defprivtype => 'DES'
          }}
          it { is_expected.to compile.and_raise_error(/Invalid default privacy type/)}
        end
        context "with fips on and MD5 as authtype in user array" do
          let(:params) {{
            :fips          => true,
            :v3_users_hash => {
               :baduser => {
                 :authtype => 'MD5',
                 :authpass => 'Passw0rdPassword'
               }
            }
          }}
          it { is_expected.to compile.and_raise_error(/failed to create user/)}
        end
      end
    end
  end
end
