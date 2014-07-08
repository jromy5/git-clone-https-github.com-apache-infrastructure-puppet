#/etc/puppet/modules/pam/manifests/insertline.pp

#
# insertline is used by other modules to insert lines in pam config files
#
  define pam::insertline(
    $pam_facility="",
    $pam_control="",
    $pam_modulepath="",
    $pam_modopts="",
    $target = "",


    $order=40,
    $commentmarker="#",


    ) {

    if $target != "" {
      $body = "$pam_facility\t\t\t$pam_control\t\t\t$pam_modulepath\t\t\t$pam_modopts"
      if $body == "" {
        $body = "$commentmarker Empty line inserted by $name.  Check your puppet config."
      }

      concat::fragment{"insertline_$name":
      target  => $target,
      order   => $order,
      content => "\n$commentmarker Line inserted by puppet ($name),  at order $order.\n$body\n"
     }
   }
}

