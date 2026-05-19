#!/bin/bash
# Script to create GUI settings page for an additional inverter instance
# Usage: ./create-gui-for-instance.sh <instance_number>

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "$1" ]; then
    echo "Error: Instance number required"
    echo "Usage: $0 <instance_number>"
    echo "Example: $0 2"
    exit 1
fi

INSTANCE_ID=$1

if ! [[ "$INSTANCE_ID" =~ ^[2-9]$|^[1-9][0-9]$ ]]; then
    echo "Error: Instance number must be between 2 and 99"
    exit 1
fi

# Create GUI-v1 file
GUI_V1_FILE="$SCRIPT_DIR/gui/PageSettingsHuaweiSUN2000_${INSTANCE_ID}.qml"
cat > "$GUI_V1_FILE" << EOF
import QtQuick 2
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage {
	title: qsTr("Huawei SUN2000 #${INSTANCE_ID}")
	property string settings: "com.victronenergy.settings/Settings/HuaweiSUN2000_${INSTANCE_ID}"

	model: VisibleItemModel {
                MbEditBoxIp {
                        id: modbusHost
                        description: qsTr("Modbus host IP")
                        item.bind: Utils.path(settings, "/ModbusHost")
                }

		MbEditBox {
			id: modbusPort
			description: qsTr("Modbus port")
			matchString: " 0123456789"
			numericOnlyLayout: true
			item.bind: Utils.path(settings, "/ModbusPort")

			function editTextToValue() {
				return parseInt(_editText, 10)
			}
		}

		MbEditBox {
			id: modbusUnit
			description: qsTr("Modbus unit")
			matchString: " 0123456789"
			numericOnlyLayout: true
			item.bind: Utils.path(settings, "/ModbusUnit")

			function editTextToValue() {
				return parseInt(_editText, 10)
			}
		}

                MbEditBox {
                        id: customName
                        description: qsTr("Custom Name")
                        item.bind: Utils.path(settings, "/CustomName")
                }

                MbItemOptions {
                        description: qsTr("Position")
                        bind: Utils.path(settings, "/Position")
                        possibleValues: [
                                MbOption { description: qsTr("AC Input 1"); value: 0 },
                                MbOption { description: qsTr("AC Input 2"); value: 2 },
                                MbOption { description: qsTr("AC Output"); value: 1 }
                        ]
                }

		MbEditBox {
			id: updateTimeMS
			description: qsTr("Update time(ms)")
			matchString: " 0123456789"
			numericOnlyLayout: true
			item.bind: Utils.path(settings, "/UpdateTimeMS")

			function editTextToValue() {
				return parseInt(_editText, 10)
			}
		}

                MbSpinBox {
                    description: qsTr("Power correction factor")
                    item {
                        bind: Utils.path(settings, "/PowerCorrectionFactor")
                        decimals: 3
                        step: 0.001
                    }
                }

	}
}
EOF

echo "Created GUI-v1 file: $GUI_V1_FILE"

# Create GUI-v2 file
GUI_V2_FILE="$SCRIPT_DIR/gui-v2/PageSettingsHuaweiSUN2000_${INSTANCE_ID}.qml"
cat > "$GUI_V2_FILE" << EOF
import QtQuick
import Victron.VenusOS

Page {
	title: qsTr("Huawei SUN2000 #${INSTANCE_ID}")

	GradientListView {
		model: ObjectModel {

			ListTextItem {
				text: qsTr("Modbus Host IP")
				secondaryText: modbusHost.value || "--"
				onClicked: Global.dialogLayer.open(modbusHostDialog)

				VeQuickItem {
					id: modbusHost
					uid: Global.systemSettings.serviceUid + "/Settings/HuaweiSUN2000_${INSTANCE_ID}/ModbusHost"
				}

				Component {
					id: modbusHostDialog
					IpAddressListDialog {
						onAccepted: modbusHost.setValue(ipAddress)
					}
				}
			}

			ListIntField {
				text: qsTr("Modbus Port")
				dataItem.uid: Global.systemSettings.serviceUid + "/Settings/HuaweiSUN2000_${INSTANCE_ID}/ModbusPort"
			}

			ListIntField {
				text: qsTr("Modbus Unit")
				dataItem.uid: Global.systemSettings.serviceUid + "/Settings/HuaweiSUN2000_${INSTANCE_ID}/ModbusUnit"
			}

			ListTextField {
				text: qsTr("Custom Name")
				dataItem.uid: Global.systemSettings.serviceUid + "/Settings/HuaweiSUN2000_${INSTANCE_ID}/CustomName"
			}

			ListRadioButtonGroup {
				text: qsTr("Position")
				dataItem.uid: Global.systemSettings.serviceUid + "/Settings/HuaweiSUN2000_${INSTANCE_ID}/Position"
				optionModel: [
					{ display: qsTr("AC Input 1"), value: 0 },
					{ display: qsTr("AC Input 2"), value: 2 },
					{ display: qsTr("AC Output"), value: 1 }
				]
			}

			ListIntField {
				text: qsTr("Update Time (ms)")
				dataItem.uid: Global.systemSettings.serviceUid + "/Settings/HuaweiSUN2000_${INSTANCE_ID}/UpdateTimeMS"
			}

			ListSpinBox {
				text: qsTr("Power Correction Factor")
				dataItem.uid: Global.systemSettings.serviceUid + "/Settings/HuaweiSUN2000_${INSTANCE_ID}/PowerCorrectionFactor"
				decimals: 3
				stepSize: 0.001
			}
		}
	}
}
EOF

echo "Created GUI-v2 file: $GUI_V2_FILE"

echo ""
echo "GUI files created. To install them:"
echo ""
echo "For GUI-v1 (Classic UI):"
echo "  1. Copy file to GUI directory:"
echo "     cp $GUI_V1_FILE /opt/victronenergy/gui/qml/"
echo "  2. Add menu entry to /opt/victronenergy/gui/qml/PageSettingsFronius.qml"
echo "     Add this inside the 'model: VisibleItemModel {' section:"
echo ""
echo "     MbSubMenu {"
echo "         description: qsTr(\"Huawei SUN2000 #${INSTANCE_ID}\")"
echo "         subpage: Component { PageSettingsHuaweiSUN2000_${INSTANCE_ID} {} }"
echo "     }"
echo ""
echo "For GUI-v2 (New UI):"
echo "  1. Copy file to GUI directory:"
echo "     cp $GUI_V2_FILE /opt/victronenergy/gui-v2/pages/settings/"
echo "  2. Add menu entry to /opt/victronenergy/gui-v2/pages/settings/PageSettings.qml"
echo "     Add after the existing Huawei entry:"
echo ""
echo "     ListNavigationItem {"
echo "         text: qsTr(\"Huawei SUN2000 #${INSTANCE_ID}\")"
echo "         onClicked: Global.pageManager.pushPage(\"/pages/settings/PageSettingsHuaweiSUN2000_${INSTANCE_ID}.qml\")"
echo "     }"
echo ""
echo "Then restart the GUI:"
echo "  svc -t /service/gui"
