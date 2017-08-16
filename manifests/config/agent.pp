# simp_snmpd::config::agent
#
# @summary This sets up some defaults for the agent, they can be changed in
# hiera
#
class simp_snmpd::config::agent {

  file { "${simp_snmpd::simp_snmpd_dir}/agent.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    require => File[$simp_snmpd::simp_snmpd_dir],
    content => epp("${module_name}/snmpd/agent.conf.epp"),
  }

}
