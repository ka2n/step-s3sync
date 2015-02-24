#!/bin/bash

set_auth() {
  local s3cnf="$HOME/.s3cfg"

  if [ -e "$s3cnf" ]; then
    warn '.s3cfg file already exists in home directory and will be overwritten'
  fi

  echo '[default]' > "$s3cnf"
  echo "access_key=$WERCKER_S3SYNC_KEY_ID" >> "$s3cnf"
  echo "secret_key=$WERCKER_S3SYNC_KEY_SECRET" >> "$s3cnf"

  debug "generated .s3cfg for key $WERCKER_S3SYNC_KEY_ID"
}

main() {
  set_auth

  info 'starting s3 synchronisation'

  if [ ! -n "$WERCKER_S3SYNC_KEY_ID" ]; then
    fail 'missing or empty option key_id, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_S3SYNC_KEY_SECRET" ]; then
    fail 'missing or empty option key_secret, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_S3SYNC_BUCKET_URL" ]; then
    fail 'missing or empty option bucket_url, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_S3SYNC_OPTS" ]; then
    export WERCKER_S3SYNC_OPTS="--acl-public"
  fi

  if [ -n "$WERCKER_S3SYNC_DELETE_REMOVED" ]; then
      if [ "$WERCKER_S3SYNC_DELETE_REMOVED" = "true" ]; then
          export WERCKER_S3SYNC_DELETE_REMOVED="--delete-removed"
      else
          unset WERCKER_S3SYNC_DELETE_REMOVED
      fi
  else
      export WERCKER_S3SYNC_DELETE_REMOVED="--delete-removed"
  fi

  set +e
  local SYNC="cd $WERCKER_S3SYNC_SOURCE_DIR && $WERCKER_STEP_ROOT/s3cmd sync $WERCKER_S3SYNC_OPTS $WERCKER_S3SYNC_DELETE_REMOVED --verbose ./ $WERCKER_S3SYNC_BUCKET_URL"
  debug "$SYNC"
  local sync_output=$($SYNC)

  if [[ $? -ne 0 ]];then
      warn "$sync_output"
      fail 's3cmd failed';
  else
      success 'finished s3 synchronisation';
  fi
  set -e
}

main
