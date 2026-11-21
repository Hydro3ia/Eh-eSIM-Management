#!/system/bin/sh
# Universal: no SIM-count assumptions. Only harmless eSIM UI props.
resetprop -n esim.enable_esim_system_ui_by_default true
resetprop -n ro.setupwizard.esim_cid_ignore 00000001
