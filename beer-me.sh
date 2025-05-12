#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/beer-me"
USAGE="usage: beer-me [environment] <resource> [-f filter]"

# print USAGE if necessary
[[ -z $@ || $@ == *--help* ]] && echo "$USAGE" && exit 0


# create directory and .envlist if necessary
[[ ! -d "$CONFIG_DIR" ]] && mkdir ~/.config/beer-me
[[ ! -a "$CONFIG_DIR/.envlist" ]] && echo "DEFAULT\tpsql postgres://postgres:@localhost:5432/postgres -c" > ~/.config/beer-me/.envlist

# Load environment command, if applicable
ENV_CMD=$(awk -F'\t' "/${1@U}/ { print \$2 }" "$CONFIG_DIR/.envlist")
if [[ -z "$ENV_CMD" ]]; then
    RESOURCE=$1
    shift # move past resource
else
    RESOURCE=$2
    shift # move past environment
    shift # move past resource
fi

POSITIONAL_ARGS=()
FILTERS_ARR=()

while [[ $# -gt 0 ]]; do
  case $1 in
      -f|--filter)
          FILTERS_ARR+=("$2")
          echo "${FILTERS_ARR[@]@Q}"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
        echo "beer-me: unreconized option $1"
        echo "$USAGE"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

NUM_FILTERS="${#FILTERS_ARR[@]}"
echo="${NUM_FILTERS@Q}"

if (( NUM_FILTERS > 0 )); then
    FILTERS=$'WHERE'
    for ((i = 0; i < NUM_FILTERS; i++ )); do
        echo "${FILTERS_ARR[i]@Q}"
        ((i != 0)) && FILTERS+=" AND"
        FILTERS+="\n    ${FILTERS_ARR[i]}"
    done
fi

# execute the query
[[ ! -a "$CONFIG_DIR/$RESOURCE.sql" ]] && echo "Missing template file for $RESOURCE: $CONFIG_DIR/$RESOURCE.sql"
QUERY=$(< "$CONFIG_DIR/$RESOURCE.sql")
if [[ -z "$ENV_CMD" ]]; then
    echo "[[ QUERY ]]"
    [[ -z "$FILTERS" ]] && \
        echo "$QUERY;" || \
        echo -e "$QUERY\n$FILTERS;"
else
    exec "$ENV_CMD" "$QUERY $FILTERS;"
fi
