#!/bin/bash
# Script to install an additional Huawei SUN2000 inverter instance
# Usage: ./install-additional-inverter.sh <instance_number>
# Example: ./install-additional-inverter.sh 2

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Check if instance number is provided
if [ -z "$1" ]; then
    echo "Error: Instance number required"
    echo "Usage: $0 <instance_number>"
    echo "Example: $0 2"
    echo ""
    echo "Instance 1 is installed by the main install.sh script."
    echo "Use this script to install additional inverters (2, 3, 4, etc.)"
    exit 1
fi

INSTANCE_ID=$1

# Validate instance number
if ! [[ "$INSTANCE_ID" =~ ^[2-9]$|^[1-9][0-9]$ ]]; then
    echo "Error: Instance number must be between 2 and 99"
    exit 1
fi

if [ "$INSTANCE_ID" -eq 1 ]; then
    echo "Error: Instance 1 is installed by the main install.sh script"
    echo "Use this script only for additional inverters (2, 3, 4, etc.)"
    exit 1
fi

SERVICE_NAME="dbus-huaweisun2000-pvinverter-${INSTANCE_ID}"
echo "Installing Huawei SUN2000 Inverter Instance #${INSTANCE_ID}"
echo "Service name: ${SERVICE_NAME}"

# Create service directory for this instance
SERVICE_DIR="$SCRIPT_DIR/service-${INSTANCE_ID}"
mkdir -p "$SERVICE_DIR/log"

# Create run script for this instance
cat > "$SERVICE_DIR/run" << EOF
#!/bin/sh
SCRIPT_DIR=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
NEWPATH="\$(dirname "\$(dirname "\$SCRIPT_DIR")")/dbus-huaweisun2000-pvinverter.py"
exec 2>&1
python -u \$NEWPATH ${INSTANCE_ID}
EOF

# Create log run script
cat > "$SERVICE_DIR/log/run" << 'EOF'
#!/bin/sh
exec multilog t s25000 n4 /var/log/dbus-huaweisun2000-${INSTANCE_ID}
EOF

# Set permissions
chmod a+x "$SERVICE_DIR/run"
chmod 755 "$SERVICE_DIR/run"
chmod a+x "$SERVICE_DIR/log/run"

# Create symlink in /service
echo "Creating service symlink..."
ln -sfn "$SERVICE_DIR" "/service/$SERVICE_NAME"
echo "✓ Service installed: $SERVICE_NAME"

# Add to rc.local for reboot survival
filename=/data/rc.local
if [ ! -f $filename ]; then
    touch $filename
    chmod 755 $filename
    echo "#!/bin/bash" >> $filename
    echo >> $filename
fi

# Add this script to rc.local to reinstall after reboot
install_command="$SCRIPT_DIR/install-additional-inverter.sh $INSTANCE_ID"
grep -qxF "$install_command" $filename || echo "$install_command" >> $filename

echo ""
echo "============================================================"
echo "Installation Complete for Instance #${INSTANCE_ID}"
echo "============================================================"
echo ""
echo "Next Steps:"
echo "1. Configure settings in Venus OS GUI:"
echo "   Settings → PV Inverters → Huawei SUN2000 #${INSTANCE_ID}"
echo ""
echo "2. Required settings:"
echo "   - Modbus Host: IP address of inverter #${INSTANCE_ID}"
echo "   - Modbus Port: Usually 6607"
echo "   - Modbus Unit ID: Usually 0"
echo "   - Custom Name: Give it a unique name"
echo ""
echo "3. Check service status:"
echo "   svstat /service/$SERVICE_NAME"
echo ""
echo "4. View logs:"
echo "   tail -f /var/log/dbus-huaweisun2000-${INSTANCE_ID}/current | tai64nlocal"
echo ""
echo "5. Verify DBus service:"
echo "   dbus -y com.victronenergy.pvinverter.sun2000_${INSTANCE_ID} /Ac/Power GetValue"
echo ""
echo "============================================================"
