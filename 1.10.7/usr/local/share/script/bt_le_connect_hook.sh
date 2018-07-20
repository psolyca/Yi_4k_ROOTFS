#!/bin/sh
sysl=`ps | grep syslogd | grep -v grep`
LOGGER ()
{
	if [ "${sysl}" == "" ]; then
		echo "$@"
	else
		logger "$@"
	fi
}

sleep 0.5
LOGGER "$@"

HCI_LE_Set_Advertising_Parameters ()
{
	LE_Controller_Commands_OGF=0x08
	HCI_LE_Set_Advertising_Parameters_OCF=0x0006
	#500 ms
	Advertising_Interval_Min="20 03"
	#4 sec
	Advertising_Interval_Max="00 19"
	Advertising_Type_Connectable="00"
	Own_Address_Type_public=00
	Direct_Address_Type_public=00
	Direct_Address="00 00 00 00 00 00"
	Advertising_Channel_Map_all=07
	Advertising_Filter_Policy_nowhite=00

	hcitool cmd $LE_Controller_Commands_OGF $HCI_LE_Set_Advertising_Parameters_OCF $Advertising_Interval_Min $Advertising_Interval_Max \
	$Advertising_Type_Connectable $Own_Address_Type_public $Direct_Address_Type_public $Direct_Address \
	$Advertising_Channel_Map_all $Advertising_Filter_Policy_nowhite
}

#GATT connected: reduce power consumption by disable piscan
if [ "${1}" == "connected" ]; then
	hciconfig hci0 noscan
fi

#GATT disconnected: restore piscan status, restart advertising
if [ "${1}" == "leadv" ]; then
	bt_conf=`cat /pref/bt.conf | grep -Ev "^#"`
	export `echo "${bt_conf}"|grep -vI $'^\xEF\xBB\xBF'`

	if [ "${PSCAN}" == "yes" ] && [ "${ISCAN}" == "yes" ] && [ $BT_DISCOVERABLE_TIMEOUT -eq 0 ]; then
		hciconfig hci0 piscan
	elif [ "${ISCAN}" == "yes" ] && [ $BT_DISCOVERABLE_TIMEOUT -eq 0 ]; then
		hciconfig hci0 iscan
	elif [ "${PSCAN}" == "yes" ]; then
		hciconfig hci0 pscan
	fi
fi

#fix bluez5 hci_le_set_advertise_enable segmentation fault
if [ "${1}" == "leadv5" ]; then
	#hciconfig hci0 noleadv
	#HCI_LE_Set_Advertising_Parameters
	hciconfig hci0 leadv
fi
