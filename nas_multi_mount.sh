#!/bin/bash
MOUNT_PATH_BASE="/media"
NAS_LIST=("nas" "nasvm" "nasbox")
declare -A NAS_IP_LIST
NAS_IP_LIST+=( ["nas"]="192.168.1.5" ["nasvm"]="192.168.1.6" ["nasbox"]="192.168.1.7" )
declare -A NAS_SHARE_PATH
NAS_SHARE_PATH_LIST+=( ["nas"]="data" ["nasvm"]="data" ["nasbox"]="data" )
declare -A NAS_MOUNT_NAME_PATH_LIST
NAS_MOUNT_NAME_PATH_LIST+=( ["nas"]="NAS" ["nasvm"]="NASVM" ["nasbox"]="NASBOX" )

# for key in ${!NAS_IP_LIST[@]}; do
#     echo ${key} ${NAS_IP_LIST[${key}]}
# done

SELECTED_NAS=""


function is_mounted() {
    # mount | awk -v DIR="$1" '{if ($3 == DIR) { exit 0}} ENDFILE{exit -1}'
    mountpoint -q "$1"
}

function mount_nas {   
    NAS_URL=""
    NAS_URI=""
    NAS_SHARE_PATH=""
    NAS_MOUNT_PATH=""

    SELECTED_NAS=$1

    if [[ " ${NAS_LIST[*]} " =~ " ${SELECTED_NAS} " ]]; then
        # whatever you want to do when array contains value
        echo "NAS selected: ${SELECTED_NAS} is valid!!!"
        # echo ${NAS_IP_LIST[${1}]}

        NAS_URL="//${NAS_IP_LIST[${1}]}/"
        NAS_URI="${NAS_URL}${NAS_SHARE_PATH_LIST[${1}]}"

        NAS_SHARE_PATH="${NAS_SHARE_PATH_LIST[${1}]}"
        NAS_MOUNT_PATH="${MOUNT_PATH_BASE}/${NAS_MOUNT_NAME_PATH_LIST[${1}]}"
    else
        # whatever you want to do when array does not contains value
        echo "NAS selected: ${SELECTED_NAS} is NOT valid!!!"
        exit
    fi

    smbclient -L $NAS_URL -U=share%share | grep -i ${NAS_SHARE_PATH}   
    if [ $? -eq 0 ]; then  # check the exit code
        echo "Nas is online, mounting ${NAS_URI} to ${NAS_MOUNT_PATH}"
        if is_mounted ${NAS_MOUNT_PATH}; then
            echo "${NAS_MOUNT_PATH} is mounted exit"
        else
            echo "${NAS_MOUNT_PATH} is not mounted, mounting"
            sudo mkdir -p ${NAS_MOUNT_PATH}
            sudo mount -t cifs -o username=share,password=share,uid=1000,gid=1000 ${NAS_URI} ${NAS_MOUNT_PATH}
        fi
    else
        echo "Nas is ${NAS_URI} offline"
        exit
    fi
}

create_menu ()
{
#   "Size of array: $#"
#   "Items of array: $@"
  echo "NAS availables: $# [$@]"

   select option; do # in "$@" is the default
    if [ "$REPLY" -eq $(($#+1)) ];
    then
      echo "Exiting..."
      exit
    # elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $(($#-1)) ];
    elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $(($#)) ];
    then
      echo "You selected NAS: $option"    
      mount_nas $option
      exit
    else
      echo "Incorrect Input: Select a number 1-$#"
    fi
  done

}

if [ $# -eq 0 ]; then
    >&2 echo "No arguments provided"
    create_menu "${NAS_LIST[@]}"
else
    mount_nas $1
fi
