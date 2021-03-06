# simp_snmpd::config::tcpwrappers
#
# @summary This class is meant to be called from simp_snmp.
# It ensures that tcpwrappers rules are defined.
#
class simp_snmpd::config::tcpwrappers {
  assert_private()

  include '::tcpwrappers'

  tcpwrappers::allow { 'snmpd':
    pattern => $simp_snmpd::trusted_nets
  }
}
