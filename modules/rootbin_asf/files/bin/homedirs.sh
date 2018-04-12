#!/bin/sh

ccaddr=${CCADDR:=infrastructure-nags@apache.org}

perms() {
  local user_dir=$1
  local me="$2"

  dirs=$(find /home/$user_dir -type d -perm -a+w -exec ls -ld {} \;)

  if [ -z $dirs ]; then
    return
  fi

  f=/tmp/$user_dir.$$-perms.tmp

  cat <<END_BODY > $f
Hi $me,

You currently have the following world writable directories(a+w) in your home
dir [/home/$user_dir] on minotaur(people.apache.org).  Please change this
to be user(u+w) or user/group(u+w/g+w) only.

$dirs

Thanks,

Apache Infrastructure
END_BODY

  cat $f | mail -s "/home/$user_dir has world writable directories!!" -c $ccaddr $user_dir
  rm -f $f
}

sshkeys() {
  local user_dir=$1
  local me="$2"

  keys=$(find /home/$user_dir -maxdepth 2 -name "identity" -o -name "id_dsa" -o -name "id_rsa")

  if [ -z "$keys" ]; then
    return
  fi

  f=/tmp/$user_dir.$$-sshkeys.tmp
  cat <<END_BODY > $f
Hi $me,

Your home directory [/home/$user_dir] on minotaur(people.apache.org) has
PRIVATE ssh keys in it.  You should consider these keys compromised
and remove them from ASF hardware and replace them as soon as possible.  You
should never store sensitive key related data on any public machines whether
ASF hardware or not.

$keys

You should instead use the the unix paradigm
eval \`ssh-agent\`
ssh-add
ssh -A

or, on Windows, putty's pageant and related tools
to 'forward' your keys along.

While we have your attention, please remember to use good passphrases
on your keys.

See the documentation at:
http://apache.org/dev/#committers
http://apache.org/dev/new-committers-guide.html#ssh
http://apache.org/dev/user-ssh.html

Apache Infrastructure
END_BODY

  cat $f | mail -s "ACTION required ~15 days; /home/$user_dir has private SSH keys" -c $ccaddr $user_dir
  rm -f $f
}

gpg() {
  local user_dir=$1
  local me="$2"

  dirs=$(find /home/$user_dir -maxdepth 2 -name secring.gpg ! -empty)
  if [ -z $dirs ]; then
    return
  fi

  f=/tmp/$user_dir.$$-gpg.tmp
  cat <<END_BODY > $f
Hi $me,

Your home directory [/home/$user_dir] on minotaur(people.apache.org) has
PRIVATE gpg or related keys in it.  You should consider these keys compromised
and remove them from ASF hardware and replace them as soon as possible.  You
should never store sensitive key related data on any public machines whether
ASF hardware or not.

If you've used this key to sign releases, you will need to resign them if you
remove/replace the key, please don't forget.

$dirs

Apache Infrastructure
END_BODY

  cat $f | mail -s "/home/$user_dir has private gpg keys" -c $ccaddr $user_dir
  rm -f $f
}

size() {
  local user_dir=$1
  local me="$2"

  ### Exceptions list
  # pgollucci - 2010/03/01
  if [ "$user_dir" = "dblevins" ]; then ## needs space for tcks
    return;
  fi
  #

  size=$(/usr/bin/du -h -m -d 0 /home/$user_dir | awk '{print $1}')

  if [ $size -lt 3768 ]; then
    return
  fi

  f=/tmp/$user_dir.$$-size.tmp
  cat <<END_BODY > $f
Hi $me,

Your home directory(/home/$user_dir) on minotaur(people.apache.org)
is currently over 2.0 GB [$size].  Please delete some things
to bring your current disk usage to 2.0 GB or under.

Thanks,

Apache Infrastructure
END_BODY
  cat $f | mail -s "/home/$user_dir is $size MB" -c $ccaddr $user_dir
  rm -f $f
}

svnpw() {
  local user_dir=$1
  local me="$2"

  # pgollucci - 2010/03/02
  if [ "$user_dir" = "upayavira" ]; then ## incubator marvin, tmp
    return;
  fi
  # pgollucci - 2010/03/01
  if [ "$user_dir" = "jim" ]; then ## committers page, others, tmp
    return;
 fi

  files=$(grep -Rl password /home/$user_dir/.subversion/auth/svn.simple)

  if [ -z "$files" ]; then
    return
  fi

  f=/tmp/$user_dir.$$-svnwp.tmp
  cat <<END_BODY > $f
Hi $me,

Your home directory(/home/$user_dir) on minotaur(people.apache.org)
contains your unencrypted CLEAR TEXT svn.apache.org password.

$files

To fix this simply remove the file(s) in question.
Then set 'store-passwords = no' in the [auth] section
of your ~/.subversion/config, otherwise set
'store-plaintext-passwords = no' in the [global] section
of your ~/.subversion/servers file.


Thanks,

Apache Infrastructure
END_BODY

  cat $f | mail -s "/home/$user_dir has plain text svn passwords" -c $ccaddr $user_dir
  rm -f $f
}

contactable() {
  local user_dir=$1
  local me="$2"

  f=/home/$user_dir/.forward
  q=/home/$user_dir/.qmail
  ff=0
  qf=0
  if [ -e $f ]; then
    ff=1
    fc=$(cat $f)
  fi
  if [ -e $q ]; then
    qf=1
    qc=$(cat $q)
  fi

  log=
  last=$(lastlogin $user_dir)

  if [ $ff -eq 0 -a $qf -eq 0 ]; then
    log="has neither $q or $f"

  elif [ $ff -eq 1 -a $qf -eq 1 ]; then
    log="has BOTH $q and $f"

    if [ -z "$fc" ]; then
      log=$log $(echo -e "\t$f is empty")
    fi
    if [ -z "$qc" ]; then
      log=$log $(echo -e "\t$q is empty")
    fi

    if [ "$fc"x != "$qc"x ]; then
      log=$log $(echo -e "\t (f)$fc != (q)$qc")
    fi
  elif [ $ff -eq 1 ]; then
    if [ -z "$fc" ]; then
      log="has empty $f"
    else
      rc=$(echo $fc | grep -c @)
      if [ $rc -ne 1 ]; then
        log="contains <> 1 '@': [$fc]"
      fi
    fi
  elif [ $qf -eq 1 ]; then
    if [ -z "$qc" ]; then
      log="has empty $q"
    else
      rc=$(echo $qc | grep -c @)
      if [ $rc -ne 1 ]; then
        log="contains <> 1 '@': [$qc]"
      fi
    fi
  fi

  if [ -z "$log" ]; then
    return
  fi

  o=/tmp/$user_dir.$$-contactable.tmp
  cat <<END_BODY > $o
$me ($user_dir@): $log $last
END_BODY

  ## intentionally, no cc addr since theorectically, they can't get this e-mail
  cat $o >> /tmp/contactable.txt
  rm -f $o
}

main() {

  cd /home
  for user_dir in ${1:-*}; do
    [ -d $user_dir ] || continue
    case $user_dir in
        apbackup|apbuildbot|apconfluence|apmail|apmirror|applanet|apsite|apcron|cvs|svn|svnwc|cvspublic|amanda|dnscache|dnslog|mrtg|tetsuya)
        continue;;
    esac

    me=$(finger -m $user_dir |grep Name |sed -e 's,.*Name: ,,')

#    size $user_dir "$me"
#    perms $user_dir "$me"
#    gpg $user_dir "$me"
#    sshkeys $user_dir "$me"
#    svnpw $user_dir "$me"
#    contactable $user_dir "$me"
  done
}

main
