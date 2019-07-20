#!/system/bin/sh

#NOTE: THIS SCRIPT IS PREPARE TO RUN IN ash SHELL WITHOUT "[" AND "test" COMMANDS.
#      THIS IS THE REASON OF "case/esac" ABUSE INSTEAD USING "if/then".
#      AND THE REASON TO USE "while true" LOOPS


#set path only with android commands, ie remove /system/xbin from path
#export PATH=/sbin:/vendor/bin:/system/sbin:/system/bin
#SM_GUIFD=""
#Description: Tests if is running Script Manager
isRunningSM()
{
case "X$SM_GUIFD" in
  X)
    return 1
    ;;
  *)
    return 0
    ;;
esac
}
#Define functions depending of if we are executing under Script Manager or standard shell
if isRunningSM ; then
#Funtions in order to use with Script Manager

#Description: Surround each argument with double quotes
  composeArgs()
  {
  local args=""
  while true ; do
  case $# in
    0)
    break
    ;;
  esac
  args=$args"\"$1\" "
  shift
  done
  echo "$args"
  }
#Description: Sends desired dialog or toast to show to Script Manager
  executeAction()
  {
  local ret
  local action
  action=$1
  shift
  case $action in
  showToastShort|showToastLong)
  echo $action $@  >&$SM_GUIFD
  ;;
  *)
    echo $action "$(composeArgs "$@")"  >&$SM_GUIFD
    #read return value
    read ret <&$SM_GUIFD
    echo $ret
    ;;
  esac
  }
else
#Funtions in order to use with standard shell
#shows message in shell
  showMessage()
  {
  case $# in
   0|1)
   ;;
   *)
    echo $1: >&2
    shift
    ;;
  esac
  echo $1 >&2
  }
#waits until y or n is pressed
  getYesNoCancel()
  {
  local ret
  ret=""
  while true ; do
  echo Yes/No?[y/n] >&2
  read ret
  case $ret in
    y|n)
    break;
    ;;
    *)
    echo Invalid option >&2
    ;;
  esac
  done
  echo $ret
  }
#shows numbered all options
  showOptions()
  {
  local nAr=$#
  local i=1
  while true ; do
    echo $i - $1 >&2
    shift
    case $# in
    0)
      break
    ;;
    esac
    i=$(let $i + 1)
  done
  }
#primitive seq command
  myseq()
  {
  local sequence="1"
  local i=1
  while true ; do
  case $i in
    $1)
      break
    ;;
  esac
  i=$(let $i + 1)
  sequence="$sequence $i"
  done
  echo $sequence
  }
#test if option selected is valid  
  #first arg:option selected
  #rest of argument valid values
  isValidOption()
  {
  local option=$1
  local i
  shift
  for i in $* ; do
    case $i in
      $option)
        return 0
        ;;
    esac
  done
  return 1
  
  }
#ask for one option  
  getOption()
  {
  local res
  while true ; do
    echo Select option between 1 and $1 >&2
    read res
    if isValidOption "$res" $(myseq $1) ; then break ; fi
  done
  echo $res
  }
#ask for several options
  getOptions()
  {
  local res
  local allValid
  while true ; do
    echo Select spaced options between 1 and $1 >&2
    read res
    allValid=1
    for i in $res ; do
      if ! isValidOption $i $(myseq $1) ; then allValid=0;break ; fi
    done
      case $allValid in
      1)
      break
      ;;
      esac
  done
  echo $res
  }
#really executes each action  
  executeAction()
  {
  local ret=""
  local action
  local default
  action=$1
  shift
  default=$4
  case $action in
    showToastShort|showToastLong)
    echo $* >&2
    ;;
    showYesNoDialog)
    showMessage "$@"
    getYesNoCancel
    ;;
    showInputDialog|showInputPasswordDialog)
    showMessage "$@"
    
    #dont show default value if it has value
      case ${action}${default}X in
      showInputPasswordDialogX|showInputDialog*)
      ;;
      *)
      default=xxxxxxxx
      ;;
      esac
    #show default value
      case X$default in
      X)
      ;;
      *)
      echo [$default] >&2
      ;;
      esac
    
    
      read ret
      case $ret in
      "")
        #if nothing input use default value
        ret=$4
      ;;
      esac
      echo $ret
    ;;
    showSpinnerDialog)
    title=$1
    shift
      echo $title: >&2
      showOptions "$@"
      getOption $#
    ;;
    showSpinnerMultiselectDialog)
    title=$1
    shift
      echo $title: >&2
      showOptions "$@"
      getOptions $#
    ;;
  esac
  }
fi

###################################################################################

#Number of arguments undefined
#return value: none
showToastShort()
{
executeAction showToastShort "$@"
}
showToastLong()
{
executeAction showToastLong "$@"
}
#Number of allowed arguments 1 or 2
#1 argument => only shows message
#2 arguments => first argument title. Second argument message
#more arguments, ignored
#return value: y , n or empty string if dialog was cancelled
showYesNoDialog()
{
executeAction showYesNoDialog "$@"
}
#Number of allowed arguments 1, 2, 3 or 4
#1 argument
#     only shows message
#2 arguments 
#     first argument title
#     Second argument message
#3 arguments 
#     first argument title. 
#     Second argument message. 
#     Third argument hint text (not used in text mode)
#4 arguments
#     first argument title. 
#     Second argument message. 
#     Third argument hint text (not used in text mode)
#     Fourth default text
#return value: typed string or empty string if dialog was cancelled
showInputDialog()
{
executeAction showInputDialog "$@"
}
showInputPasswordDialog()
{
executeAction showInputPasswordDialog "$@"
}

#Number or arguments 2 or more
#     first argument title
#     rest of arguments are options
#return value: selected index option. (First option is 1)
#              Empty string if dialog was cancelled
showSpinnerDialog()
{
executeAction showSpinnerDialog "$@"
}
#Number or arguments 2 or more
#     first argument title
#     rest of arguments are options
#return value: space separate selected options. (First option is 1). 
#              Empty string for no selections or cancelled dialog
showSpinnerMultiselectDialog()
{
executeAction showSpinnerMultiselectDialog "$@"
}


##########################################     Main program     #############################
#test if passed argument is empty. If it is empty cancel script
test_emty()
{
case X$1 in
X)
  echo Backup canceled
  exit 127
;;
esac
}


showToastLong "Backup script example"

case $(showYesNoDialog "Make copy?" "Do you want really backup your data?") in
  y)
  ;;
  *)
  echo Backup canceled
  showToastShort "Backup canceled"
  exit 127
  ;;
esac
machine1="mach1"
machine2="mach2"
machine3="mach2"
ret=$(showSpinnerDialog "Select remote host" $machine1 $machine2 $machine3)
test_emty $ret

eval machine="\$machine$ret"
echo Bakup is going to do in $machine

dir1=/data/data/com.android.providers.telephony
dir2=/sdcard/DCIM
dir3=/data/app
ret=$(showSpinnerMultiselectDialog "Select dirs to backup" $dir1 $dir2 $dir3)
test_emty $ret

dirs=""
dirsAux=""
for i in $ret ; do
eval dirsAux="\$dir$i"
dirs="$dirs $dirsAux"
done
echo Directories to backup $dirs

username=$(showInputPasswordDialog "$machine username" "Enter username in remote host" user)
test_emty $username

outname=$(showInputDialog "Backup filename" "Input backup filename" \
        filename.tgz bkup_$(date "+%Y_%m_%d__%H_%M_%S").tgz)
test_emty $outname

echo backup to remote file $outname

tar cz $dirs|ssh $username@$machine "dd of=$outname"

