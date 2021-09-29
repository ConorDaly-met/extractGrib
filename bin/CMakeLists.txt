function (install_scripts)
  foreach (file ${ARGV})
    get_filename_component (name_without_extension ${file} NAME_WE)
    install (FILES ${file}
             PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
             DESTINATION bin 
             RENAME ${name_without_extension})
  endforeach ()
endfunction()

install_scripts (do_paramset.sh extractGrib.sh extract_FA.sh FA_namelist.sh grib_paramlist.sh grib_proj.sh make_subdomain.sh merge_pppkey.sh read_paramlist.sh)
