#!/system/bin/sh
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING 
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING 
#
# If you disable system packages youd device may not boot up.
# If you can't boot up, may be you can reenable it using adb, the best option is a wipe
#
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING 
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING 

# USAGE: $0 [enable|disable|package.name]
#     enable: shows a list with disabled packages, selected packages will be enabled
#     disable: shows a list with all packages. Selected packages will be disabled 
#     package.name: package package.name will be disabled
#
# NOTE: this script only works with Script Manager, but you can easily use without it replacing showSpinnerMultiselectDialog usages
#

[ "$(whoami)" != "root" ] && echo root permission required && exit 1

disable()
{
  PACKS=$(pm list packages |cut -f2 -d:) 
  echo showSpinnerMultiselectDialog \"Select package to disable\" $PACKS >&$SM_GUIFD
  read res <&$SM_GUIFD
  for n in $res ; do
    PACK2="$PACK2 $(echo $PACKS|cut -d" " -f $n)"
  done
  for p in $PACK2 ; do
    pm disable $p
  done
}

enable()
{
  LP=$(pm list packages -d)
  [ -z "$LP" ] && echo No Disabled packages && return
  PACKS=$(echo "$LP" |cut -f2 -d:) 
  echo showSpinnerMultiselectDialog \"Select package to enable\" $PACKS >&$SM_GUIFD
  read res <&$SM_GUIFD
  for n in $res ; do
    PACK2="$PACK2 $(echo $PACKS|cut -d" " -f $n)"
  done
  for p in $PACK2 ; do
    pm enable $p
    #dumpsys package -f "$p"
    BOOT=$(dumpsys package -f "$p"|grep -B1 "Action: \"android.intent.action.BOOT_COMPLETED\"")
    if [ -n "$BOOT" ] ; then
      COMPONENT="$(echo "$BOOT"|head -n1|awk '{print $2;}')"
      if [ -n "$COMPONENT" ] ; then
      am broadcast -a android.intent.action.BOOT_COMPLETED -n $COMPONENT
      fi
    fi
  done
}

  case "$1" in
  enable)
  enable
    ;;
  disable)
  disable
    ;;
  *)
     echo disabling $1
     pm disable $1 
    ;;
esac
