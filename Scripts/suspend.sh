#!/bin/bash

stat=$(cat /proc/acpi/wakeup)
wakers=(XHC GLAN)
for waker in ${wakers[@]}; do 
  is_en=$(echo "${stat}" | grep $waker | grep disabled);
  if [ -z "$is_en" ]; then 
    echo disable wakeup of $waker
    echo $waker | tee /proc/acpi/wakeup
  fi
done


