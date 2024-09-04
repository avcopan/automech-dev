#!/usr/bin/env bash

# Optionally, read in the subtask directory path with a `-p` argment
# (Must be the first argument)
SUBTASK_PATH="subtasks"
SUBTASK_LOG="sub.log"
ARG_OFFSET=1
while getopts ":p:o:" opt; do
  case $opt in
    p)
      SUBTASK_PATH=$OPTARG
      ARG_OFFSET=$((ARG_OFFSET+2))
      ;;
    o)
      SUBTASK_LOG=$OPTARG
      ARG_OFFSET=$((ARG_OFFSET+2))
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Read in the list of nodes
read -a NODES <<< "${@:ARG_OFFSET}"
FIRST_NODE=${NODES[0]}
NODES_CSV="$(printf '%s,' ${NODES[@]})"

echo "Arguments:"
echo "  SUBTASK_PATH=${SUBTASK_PATH}"
echo "  SUBTASK_LOG=${SUBTASK_LOG}"
echo "  NODES_CSV=${NODES_CSV}"

ACTIVATION_HOOK="$(pixi shell-hook)"
RUN_COMMAND="automech subtasks run-adhoc -p ${SUBTASK_PATH} -n ${NODES_CSV} -a ${ACTIVATION_HOOK@Q}"
SCRIPT_HEADER='
    echo Running on $(hostname) in $(pwd)
    echo Process ID: $$
'
SCRIPT="
    ${SCRIPT_HEADER}
    echo Run command: ${RUN_COMMAND}
    ${RUN_COMMAND}
"

# Determine the user's working directory
WD=${INIT_CWD:-$(pwd)}

# Enter working directory and initiate job from the first SSH node
cd ${WD} && ssh ${FIRST_NODE} /bin/env bash << EOF
    set -e
    cd ${WD}
    ${SCRIPT_HEADER}
    eval ${ACTIVATION_HOOK@Q}
    nohup sh -c ${SCRIPT@Q} > ${SUBTASK_LOG} 2>&1 &
EOF