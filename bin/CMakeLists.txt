#function (install_scripts)
#  foreach (file ${ARGV})
#    install (FILES ${file}
#             PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ
#             DESTINATION bin 
#              )
#  endforeach ()
#endfunction()
#
#install_scripts (do_paramset.sh extractGrib extract_FA.sh FA_namelist.sh grib_paramlist.sh grib_proj.sh make_subdomain.sh merge_pppkey.sh read_paramlist.sh)
install( DIRECTORY . DESTINATION bin PATTERN "CMakeLists.txt" EXCLUDE )

