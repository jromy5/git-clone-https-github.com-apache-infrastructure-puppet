class pam (

  ## Files being managed. These are the default
  ## values. As these seem like generic sane defaults.
  ## However you should note that hiera should be populating them.
  $pam_sshd   = "",
  $pam_su     = "",
  $pam_system = "",


  ## Content variables, as found in hiera data
  $generic_header  = "",


  ## Data variables

  ## pam.d/sshd
  $sshd_10_facility   = "",
  $sshd_10_control    = "",
  $sshd_10_modulepath = "",
  $sshd_10_modopts    = "",

  $sshd_15_facility   = "",
  $sshd_15_control    = "",
  $sshd_15_modulepath = "",
  $sshd_15_modopts    = "",

  $sshd_20_facility   = "",
  $sshd_20_control    = "",
  $sshd_20_modulepath = "",
  $sshd_20_modopts    = "",

  $sshd_25_facility   = "",
  $sshd_25_control    = "",
  $sshd_25_modulepath = "",
  $sshd_25_modopts    = "",

  $sshd_30_facility   = "",
  $sshd_30_control    = "",
  $sshd_30_modulepath = "",
  $sshd_30_modopts    = "",

  $sshd_35_facility   = "",
  $sshd_35_control    = "",
  $sshd_35_modulepath = "",
  $sshd_35_modopts    = "",

  $sshd_40_facility   = "",
  $sshd_40_control    = "",
  $sshd_40_modulepath = "",
  $sshd_40_modopts    = "",

  $sshd_45_facility   = "",
  $sshd_45_control    = "",
  $sshd_45_modulepath = "",
  $sshd_45_modopts    = "",

  $sshd_50_facility   = "",
  $sshd_50_control    = "",
  $sshd_50_modulepath = "",
  $sshd_50_modopts    = "",

  $sshd_55_facility   = "",
  $sshd_55_control    = "",
  $sshd_55_modulepath = "",
  $sshd_55_modopts    = "",

  $sshd_60_facility   = "",
  $sshd_60_control    = "",
  $sshd_60_modulepath = "",
  $sshd_60_modopts    = "",

  $sshd_65_facility   = "",
  $sshd_65_control    = "",
  $sshd_65_modulepath = "",
  $sshd_65_modopts    = "",

  $sshd_70_facility   = "",
  $sshd_70_control    = "",
  $sshd_70_modulepath = "",
  $sshd_70_modopts    = "",

  $sshd_75_facility   = "",
  $sshd_75_control    = "",
  $sshd_75_modulepath = "",
  $sshd_75_modopts    = "",

  $sshd_80_facility   = "",
  $sshd_80_control    = "",
  $sshd_80_modulepath = "",
  $sshd_80_modopts    = "",

  $sshd_85_facility   = "",
  $sshd_85_control    = "",
  $sshd_85_modulepath = "",
  $sshd_85_modopts    = "",

  $sshd_90_facility   = "",
  $sshd_90_control    = "",
  $sshd_90_modulepath = "",
  $sshd_90_modopts    = "",

  $sshd_95_facility   = "",
  $sshd_95_control    = "",
  $sshd_95_modulepath = "",
  $sshd_95_modopts    = "",

  $sshd_100_facility   = "",
  $sshd_100_control    = "",
  $sshd_100_modulepath = "",
  $sshd_100_modopts    = "",


  ## pam.d/su 
  $su_10_facility   = "",
  $su_10_control    = "",
  $su_10_modulepath = "",
  $su_10_modopts    = "",

  $su_15_facility   = "",
  $su_15_control    = "",
  $su_15_modulepath = "",
  $su_15_modopts    = "",

  $su_20_facility   = "",
  $su_20_control    = "",
  $su_20_modulepath = "",
  $su_20_modopts    = "",

  $su_25_facility   = "",
  $su_25_control    = "",
  $su_25_modulepath = "",
  $su_25_modopts    = "",

  $su_30_facility   = "",
  $su_30_control    = "",
  $su_30_modulepath = "",
  $su_30_modopts    = "",

  $su_35_facility   = "",
  $su_35_control    = "",
  $su_35_modulepath = "",
  $su_35_modopts    = "",

  $su_40_facility   = "",
  $su_40_control    = "",
  $su_40_modulepath = "",
  $su_40_modopts    = "",

  $su_45_facility   = "",
  $su_45_control    = "",
  $su_45_modulepath = "",
  $su_45_modopts    = "",

  $su_50_facility   = "",
  $su_50_control    = "",
  $su_50_modulepath = "",
  $su_50_modopts    = "",

  $su_55_facility   = "",
  $su_55_control    = "",
  $su_55_modulepath = "",
  $su_55_modopts    = "",

  $su_60_facility   = "",
  $su_60_control    = "",
  $su_60_modulepath = "",
  $su_60_modopts    = "",

  $su_65_facility   = "",
  $su_65_control    = "",
  $su_65_modulepath = "",
  $su_65_modopts    = "",

  $su_70_facility   = "",
  $su_70_control    = "",
  $su_70_modulepath = "",
  $su_70_modopts    = "",

  $su_75_facility   = "",
  $su_75_control    = "",
  $su_75_modulepath = "",
  $su_75_modopts    = "",

  $su_80_facility   = "",
  $su_80_control    = "",
  $su_80_modulepath = "",
  $su_80_modopts    = "",

  $su_85_facility   = "",
  $su_85_control    = "",
  $su_85_modulepath = "",
  $su_85_modopts    = "",

  $su_90_facility   = "",
  $su_90_control    = "",
  $su_90_modulepath = "",
  $su_90_modopts    = "",

  $su_95_facility   = "",
  $su_95_control    = "",
  $su_95_modulepath = "",
  $su_95_modopts    = "",

  $su_100_facility   = "",
  $su_100_control    = "",
  $su_100_modulepath = "",
  $su_100_modopts    = "",


  ## pam.d/system
  $system_10_facility   = "",
  $system_10_control    = "",
  $system_10_modulepath = "",
  $system_10_modopts    = "",

  $system_15_facility   = "",
  $system_15_control    = "",
  $system_15_modulepath = "",
  $system_15_modopts    = "",

  $system_20_facility   = "",
  $system_20_control    = "",
  $system_20_modulepath = "",
  $system_20_modopts    = "",

  $system_25_facility   = "",
  $system_25_control    = "",
  $system_25_modulepath = "",
  $system_25_modopts    = "",

  $system_30_facility   = "",
  $system_30_control    = "",
  $system_30_modulepath = "",
  $system_30_modopts    = "",

  $system_35_facility   = "",
  $system_35_control    = "",
  $system_35_modulepath = "",
  $system_35_modopts    = "",

  $system_40_facility   = "",
  $system_40_control    = "",
  $system_40_modulepath = "",
  $system_40_modopts    = "",

  $system_45_facility   = "",
  $system_45_control    = "",
  $system_45_modulepath = "",
  $system_45_modopts    = "",

  $system_50_facility   = "",
  $system_50_control    = "",
  $system_50_modulepath = "",
  $system_50_modopts    = "",

  $system_55_facility   = "",
  $system_55_control    = "",
  $system_55_modulepath = "",
  $system_55_modopts    = "",

  $system_60_facility   = "",
  $system_60_control    = "",
  $system_60_modulepath = "",
  $system_60_modopts    = "",

  $system_65_facility   = "",
  $system_65_control    = "",
  $system_65_modulepath = "",
  $system_65_modopts    = "",

  $system_70_facility   = "",
  $system_70_control    = "",
  $system_70_modulepath = "",
  $system_70_modopts    = "",

  $system_75_facility   = "",
  $system_75_control    = "",
  $system_75_modulepath = "",
  $system_75_modopts    = "",

  $system_80_facility   = "",
  $system_80_control    = "",
  $system_80_modulepath = "",
  $system_80_modopts    = "",

  $system_85_facility   = "",
  $system_85_control    = "",
  $system_85_modulepath = "",
  $system_85_modopts    = "",

  $system_90_facility   = "",
  $system_90_control    = "",
  $system_90_modulepath = "",
  $system_90_modopts    = "",

  $system_95_facility   = "",
  $system_95_control    = "",
  $system_95_modulepath = "",
  $system_95_modopts = "",

  $system_100_facility   = "",
  $system_100_control    = "",
  $system_100_modulepath = "",
  $system_100_modopts    = "",

  ) {


  ## Add our puppet warning at the top of the file.

  concat::fragment::puppetwarn::hash{"pam-sshd-puppetwarn":
    target  => $pam_sshd,
  }

  concat::fragment::puppetwarn::hash{"pam-su-puppetwarn":
    target  => $pam_su,
  }

  concat::fragment::puppetwarn::hash{"pam-system-puppetwarn":
    target  => $pam_system,
  }


  ## Add the OS generic header, 
  ## so we can track the origins of the file.

  concat::fragment{"pam-sshd-header":
    target  => $pam_sshd,
    content => $generic_header,
    order   => 005,
  }

  concat::fragment{"pam-su-header":
    target  => $pam_su,
    content => $generic_header,
    order   => 005,
  }

  concat::fragment{"pam-system-header":
    target  => $pam_system,
    content => $generic_header,
    order   => 005,
  }


  ## Generate the fragments, by calling the 
  ## custom pam::insertline module. 

  ## pam.d/sshd

  pam::insertline{"pam-sshd-10":
    target         => $pam_sshd,
    order          => "010",
    pam_facility   => $sshd_10_facility,
    pam_control    => $sshd_10_control,
    pam_modulepath => $sshd_10_modulepath,
    pam_modopts    => $sshd_10_modopts,
  }

  pam::insertline{"pam-sshd-15":
    target         => $pam_sshd,
    order          => "015",
    pam_facility   => $sshd_15_facility,
    pam_control    => $sshd_15_control,
    pam_modulepath => $sshd_15_modulepath,
    pam_modopts    => $sshd_15_modopts,
  }

  pam::insertline{"pam-sshd-20":
    target         => $pam_sshd,
    order          => "020",
    pam_facility   => $sshd_20_facility,
    pam_control    => $sshd_20_control,
    pam_modulepath => $sshd_20_modulepath,
    pam_modopts    => $sshd_20_modopts,
  }

  pam::insertline{"pam-sshd-25":
    target         => $pam_sshd,
    order          => "025",
    pam_facility   => $sshd_25_facility,
    pam_control    => $sshd_25_control,
    pam_modulepath => $sshd_25_modulepath,
    pam_modopts    => $sshd_25_modopts,
  }

  pam::insertline{"pam-sshd-30":
    target         => $pam_sshd,
    order          => "030",
    pam_facility   => $sshd_30_facility,
    pam_control    => $sshd_30_control,
    pam_modulepath => $sshd_30_modulepath,
    pam_modopts    => $sshd_30_modopts,
  }

  pam::insertline{"pam-sshd-35":
    target         => $pam_sshd,
    order          => "035",
    pam_facility   => $sshd_35_facility,
    pam_control    => $sshd_35_control,
    pam_modulepath => $sshd_35_modulepath,
    pam_modopts    => $sshd_35_modopts,
  }

  pam::insertline{"pam-sshd-50":
    target         => $pam_sshd,
    order          => "050",
    pam_facility   => $sshd_50_facility,
    pam_control    => $sshd_50_control,
    pam_modulepath => $sshd_50_modulepath,
    pam_modopts    => $sshd_50_modopts,
  }

  pam::insertline{"pam-sshd-55":
    target         => $pam_sshd,
    order          => "055",
    pam_facility   => $sshd_55_facility,
    pam_control    => $sshd_55_control,
    pam_modulepath => $sshd_55_modulepath,
    pam_modopts    => $sshd_55_modopts,
  }

  pam::insertline{"pam-sshd-60":
    target         => $pam_sshd,
    order          => "060",
    pam_facility   => $sshd_60_facility,
    pam_control    => $sshd_60_control,
    pam_modulepath => $sshd_60_modulepath,
    pam_modopts    => $sshd_60_modopts,
  }

  pam::insertline{"pam-sshd-65":
    target         => $pam_sshd,
    order          => "065",
    pam_facility   => $sshd_65_facility,
    pam_control    => $sshd_65_control,
    pam_modulepath => $sshd_65_modulepath,
    pam_modopts    => $sshd_65_modopts,
  }

  pam::insertline{"pam-sshd-70":
    target         => $pam_sshd,
    order          => "070",
    pam_facility   => $sshd_70_facility,
    pam_control    => $sshd_70_control,
    pam_modulepath => $sshd_70_modulepath,
    pam_modopts    => $sshd_70_modopts,
  }

  pam::insertline{"pam-sshd-80":
    target         => $pam_sshd,
    order          => "080",
    pam_facility   => $sshd_80_facility,
    pam_control    => $sshd_80_control,
    pam_modulepath => $sshd_80_modulepath,
    pam_modopts    => $sshd_80_modopts,
  }

  pam::insertline{"pam-sshd-85":
    target         => $pam_sshd,
    order          => "085",
    pam_facility   => $sshd_85_facility,
    pam_control    => $sshd_85_control,
    pam_modulepath => $sshd_85_modulepath,
    pam_modopts    => $sshd_85_modopts,
  }

  pam::insertline{"pam-sshd-90":
    target         => $pam_sshd,
    order          => "090",
    pam_facility   => $sshd_90_facility,
    pam_control    => $sshd_90_control,
    pam_modulepath => $sshd_90_modulepath,
    pam_modopts    => $sshd_90_modopts,
  }

  pam::insertline{"pam-sshd-95":
    target         => $pam_sshd,
    order          => "095",
    pam_facility   => $sshd_95_facility,
    pam_control    => $sshd_95_control,
    pam_modulepath => $sshd_95_modulepath,
    pam_modopts    => $sshd_95_modopts,
  }

  pam::insertline{"pam-sshd-100":
    target         => $pam_sshd,
    order          => "100",
    pam_facility   => $sshd_100_facility,
    pam_control    => $sshd_100_control,
    pam_modulepath => $sshd_100_modulepath,
    pam_modopts    => $sshd_100_modopts,
  }


  ## pam.d/su
  pam::insertline{"pam-su-10":
    target         => $pam_su,
    order          => "010",
    pam_facility   => $su_10_facility,
    pam_control    => $su_10_control,
    pam_modulepath => $su_10_modulepath,
    pam_modopts    => $su_10_modopts,
  }

  pam::insertline{"pam-su-15":
    target         => $pam_su,
    order          => "015",
    pam_facility   => $su_15_facility,
    pam_control    => $su_15_control,
    pam_modulepath => $su_15_modulepath,
    pam_modopts    => $su_15_modopts,
  }

  pam::insertline{"pam-su-20":
    target         => $pam_su,
    order          => "020",
    pam_facility   => $su_20_facility,
    pam_control    => $su_20_control,
    pam_modulepath => $su_20_modulepath,
    pam_modopts    => $su_20_modopts,
  }

  pam::insertline{"pam-su-25":
    target         => $pam_su,
    order          => "025",
    pam_facility   => $su_25_facility,
    pam_control    => $su_25_control,
    pam_modulepath => $su_25_modulepath,
    pam_modopts    => $su_25_modopts,
  }

  pam::insertline{"pam-su-30":
    target         => $pam_su,
    order          => "030",
    pam_facility   => $su_30_facility,
    pam_control    => $su_30_control,
    pam_modulepath => $su_30_modulepath,
    pam_modopts    => $su_30_modopts,
  }

  pam::insertline{"pam-su-35":
    target         => $pam_su,
    order          => "035",
    pam_facility   => $su_35_facility,
    pam_control    => $su_35_control,
    pam_modulepath => $su_35_modulepath,
    pam_modopts    => $su_35_modopts,
  }

  pam::insertline{"pam-su-50":
    target         => $pam_su,
    order          => "050",
    pam_facility   => $su_50_facility,
    pam_control    => $su_50_control,
    pam_modulepath => $su_50_modulepath,
    pam_modopts    => $su_50_modopts,
  }

  pam::insertline{"pam-su-55":
    target         => $pam_su,
    order          => "055",
    pam_facility   => $su_55_facility,
    pam_control    => $su_55_control,
    pam_modulepath => $su_55_modulepath,
    pam_modopts    => $su_55_modopts,
  }

  pam::insertline{"pam-su-60":
    target         => $pam_su,
    order          => "060",
    pam_facility   => $su_60_facility,
    pam_control    => $su_60_control,
    pam_modulepath => $su_60_modulepath,
    pam_modopts    => $su_60_modopts,
  }

  pam::insertline{"pam-su-65":
    target         => $pam_su,
    order          => "065",
    pam_facility   => $su_65_facility,
    pam_control    => $su_65_control,
    pam_modulepath => $su_65_modulepath,
    pam_modopts    => $su_65_modopts,
  }

  pam::insertline{"pam-su-70":
    target         => $pam_su,
    order          => "070",
    pam_facility   => $su_70_facility,
    pam_control    => $su_70_control,
    pam_modulepath => $su_70_modulepath,
    pam_modopts    => $su_70_modopts,
  }

  pam::insertline{"pam-su-80":
    target         => $pam_su,
    order          => "080",
    pam_facility   => $su_80_facility,
    pam_control    => $su_80_control,
    pam_modulepath => $su_80_modulepath,
    pam_modopts    => $su_80_modopts,
  }

  pam::insertline{"pam-su-85":
    target         => $pam_su,
    order          => "085",
    pam_facility   => $su_85_facility,
    pam_control    => $su_85_control,
    pam_modulepath => $su_85_modulepath,
    pam_modopts    => $su_85_modopts,
  }

  pam::insertline{"pam-su-90":
    target         => $pam_su,
    order          => "090",
    pam_facility   => $su_90_facility,
    pam_control    => $su_90_control,
    pam_modulepath => $su_90_modulepath,
    pam_modopts    => $su_90_modopts,
  }

  pam::insertline{"pam-su-95":
    target         => $pam_su,
    order          => "095",
    pam_facility   => $su_95_facility,
    pam_control    => $su_95_control,
    pam_modulepath => $su_95_modulepath,
    pam_modopts    => $su_95_modopts,
  }

  pam::insertline{"pam-su-100":
    target         => $pam_su,
    order          => "100",
    pam_facility   => $su_100_facility,
    pam_control    => $su_100_control,
    pam_modulepath => $su_100_modulepath,
    pam_modopts    => $su_100_modopts,
  }


  ## pam.d/system
  pam::insertline{"pam-system-10":
    target         => $pam_system,
    order          => "010",
    pam_facility   => $system_10_facility,
    pam_control    => $system_10_control,
    pam_modulepath => $system_10_modulepath,
    pam_modopts    => $system_10_modopts,
  }

  pam::insertline{"pam-system-15":
    target         => $pam_system,
    order          => "015",
    pam_facility   => $system_15_facility,
    pam_control    => $system_15_control,
    pam_modulepath => $system_15_modulepath,
    pam_modopts    => $system_15_modopts,
  }

  pam::insertline{"pam-system-20":
    target         => $pam_system,
    order          => "020",
    pam_facility   => $system_20_facility,
    pam_control    => $system_20_control,
    pam_modulepath => $system_20_modulepath,
    pam_modopts    => $system_20_modopts,
  }

  pam::insertline{"pam-system-25":
    target         => $pam_system,
    order          => "025",
    pam_facility   => $system_25_facility,
    pam_control    => $system_25_control,
    pam_modulepath => $system_25_modulepath,
    pam_modopts    => $system_25_modopts,
  }

  pam::insertline{"pam-system-30":
    target         => $pam_system,
    order          => "030",
    pam_facility   => $system_30_facility,
    pam_control    => $system_30_control,
    pam_modulepath => $system_30_modulepath,
    pam_modopts    => $system_30_modopts,
  }

  pam::insertline{"pam-system-35":
    target         => $pam_system,
    order          => "035",
    pam_facility   => $system_35_facility,
    pam_control    => $system_35_control,
    pam_modulepath => $system_35_modulepath,
    pam_modopts    => $system_35_modopts,
  }

  pam::insertline{"pam-system-50":
    target         => $pam_system,
    order          => "050",
    pam_facility   => $system_50_facility,
    pam_control    => $system_50_control,
    pam_modulepath => $system_50_modulepath,
    pam_modopts    => $system_50_modopts,
  }

  pam::insertline{"pam-system-55":
    target         => $pam_system,
    order          => "055",
    pam_facility   => $system_55_facility,
    pam_control    => $system_55_control,
    pam_modulepath => $system_55_modulepath,
    pam_modopts    => $system_55_modopts,
  }

  pam::insertline{"pam-system-60":
    target         => $pam_system,
    order          => "060",
    pam_facility   => $system_60_facility,
    pam_control    => $system_60_control,
    pam_modulepath => $system_60_modulepath,
    pam_modopts    => $system_60_modopts,
  }

  pam::insertline{"pam-system-65":
    target         => $pam_system,
    order          => "065",
    pam_facility   => $system_65_facility,
    pam_control    => $system_65_control,
    pam_modulepath => $system_65_modulepath,
    pam_modopts    => $system_65_modopts,
  }

  pam::insertline{"pam-system-70":
    target         => $pam_system,
    order          => "070",
    pam_facility   => $system_70_facility,
    pam_control    => $system_70_control,
    pam_modulepath => $system_70_modulepath,
    pam_modopts    => $system_70_modopts,
  }

  pam::insertline{"pam-system-80":
    target         => $pam_system,
    order          => "080",
    pam_facility   => $system_80_facility,
    pam_control    => $system_80_control,
    pam_modulepath => $system_80_modulepath,
    pam_modopts    => $system_80_modopts,
  }

  pam::insertline{"pam-system-85":
    target         => $pam_system,
    order          => "085",
    pam_facility   => $system_85_facility,
    pam_control    => $system_85_control,
    pam_modulepath => $system_85_modulepath,
    pam_modopts    => $system_85_modopts,
  }

  pam::insertline{"pam-system-90":
    target         => $pam_system,
    order          => "090",
    pam_facility   => $system_90_facility,
    pam_control    => $system_90_control,
    pam_modulepath => $system_90_modulepath,
    pam_modopts    => $system_90_modopts,
  }

  pam::insertline{"pam-system-95":
    target         => $pam_system,
    order          => "095",
    pam_facility   => $system_95_facility,
    pam_control    => $system_95_control,
    pam_modulepath => $system_95_modulepath,
    pam_modopts    => $system_95_modopts,
  }

  pam::insertline{"pam-system-100":
    target         => $pam_system,
    order          => "100",
    pam_facility   => $system_100_facility,
    pam_control    => $system_100_control,
    pam_modulepath => $system_100_modulepath,
    pam_modopts    => $system_100_modopts,
  }

}
