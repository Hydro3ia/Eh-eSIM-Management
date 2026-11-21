#!/system/bin/sh
# Enable eSIM related system properties before the framework starts.
resetprop -n esim.enable_esim_system_ui_by_default true
resetprop -n persist.radio.multisim.config dsds
resetprop -n ro.setupwizard.esim_cid_ignore 00000001
