##########################################################################################
# Defines
##########################################################################################
MODID=fp4-low-volume-fix
AUTOMOUNT=true
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=false

##########################################################################################
# Installation Message
##########################################################################################
print_modname() {
  ui_print "****************************************"
  ui_print " Fairphone 4 handset-mic low volume fix "
  ui_print "****************************************"
}

##########################################################################################
# Replace list
##########################################################################################
REPLACE="
"

##########################################################################################
# Permissions
##########################################################################################
set_permissions() {
  # Default permissions, don't remove them
  set_perm_recursive  $MODPATH  0  0  0755  0644

  # set_perm  <filename>                                          <owner> <group> <permission>    <contexts> (default: u:object_r:system_file:s0)
  set_perm  $MODPATH/system/vendor/etc/mixer_paths_lagoon_fp4.xml   0       0       0644            u:object_r:vendor_configs_file:s0
}
