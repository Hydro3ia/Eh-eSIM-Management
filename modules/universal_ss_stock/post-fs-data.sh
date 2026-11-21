#!/system/bin/sh
# Universal SS: single-SIM assumption, no multisim.config change. Only eSIM UI props.
resetprop -n esim.enable_esim_system_ui_by_default true
resetprop -n ro.setupwizard.esim_cid_ignore 00000001
