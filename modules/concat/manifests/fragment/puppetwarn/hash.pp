#
define concat::fragment::puppetwarn::hash(
    $target,
    $content="
###
##           ..:: WARNING ::..
##
##    This file is managed by puppet.
## All local changes will be lost during 
##         the next puppet run.
##
###
",
    $source=undef,
    $order=001,
    $ensure = 'present',
    $mode = '0644',
    $owner = $::id,
    $group = $concat::setup::root_group,
    $backup = 'puppet') {
  $safe_name = regsubst($name, '[/\n]', '_', 'GM')
  $safe_target_name = regsubst($target, '[/\n]', '_', 'GM')
  $concatdir = $concat::setup::concatdir
  $fragdir = "${concatdir}/${safe_target_name}"

  # if content is passed, use that, else if source is passed use that
  # if neither passed, but $ensure is in symlink form, make a symlink
  case $ensure {
    '', 'absent', 'present', 'file', 'directory': {
      if ! ($content or $source) {
        crit('No content, source or symlink specified')
      }
    }
    default: {
      # do nothing, make puppet-lint happy
    }
  }

  file{"${fragdir}/fragments/${order}_${safe_name}":
    ensure  => $ensure,
    mode    => $mode,
    owner   => $owner,
    group   => $group,
    source  => $source,
    content => $content,
    backup  => $backup,
    alias   => "concat_fragment_${name}",
    notify  => Exec["concat_${target}"]
  }
}
