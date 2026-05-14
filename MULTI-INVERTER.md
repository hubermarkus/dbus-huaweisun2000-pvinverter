# Multi-Inverter Installation Guide

This guide explains how to install and configure multiple Huawei SUN2000 inverters on Venus OS.

## Overview

The driver now supports multiple inverter instances, allowing you to monitor several Huawei SUN2000 inverters simultaneously. Each instance:
- Has its own DBus service (e.g., `com.victronenergy.pvinverter.sun2000_1`, `sun2000_2`, etc.)
- Uses separate settings paths in Venus OS persistent storage
- Has a unique VRM instance ID for portal logging
- Can be configured independently via the GUI

## Prerequisites

- Venus OS v3.x or later
- One or more Huawei SUN2000 inverters
- Network connectivity to each inverter (unique IP addresses)
- The main driver already installed (instance #1)

## Architecture

### Instance Numbering
- **Instance 1**: Installed by the main `install.sh` script (default)
- **Instance 2+**: Installed using `install-additional-inverter.sh`

Each instance is a separate daemonized service that runs independently.

### DBus Service Names
- Instance 1: `com.victronenergy.pvinverter.sun2000_1`
- Instance 2: `com.victronenergy.pvinverter.sun2000_2`
- Instance 3: `com.victronenergy.pvinverter.sun2000_3`
- And so on...

### Settings Paths
Each instance stores settings under unique paths:

**Instance 1** (backwards compatible):
- `/Settings/HuaweiSUN2000/ModbusHost`
- `/Settings/HuaweiSUN2000/ModbusPort`
- etc.

**Instance 2+**:
- `/Settings/HuaweiSUN2000_2/ModbusHost`
- `/Settings/HuaweiSUN2000_2/ModbusPort`
- etc.

### VRM Instance IDs
Each inverter automatically gets a unique VRM instance ID based on its instance number:
- Instance 1 → VRM ID: `pvinverter:1`
- Instance 2 → VRM ID: `pvinverter:2`
- Instance 3 → VRM ID: `pvinverter:3`

This ensures all inverters appear separately in VRM Portal.

## Installation Steps

### Step 1: Install Instance #1 (Main Inverter)

If not already installed, run the main installation:

```bash
ssh root@<venus-os-ip>
cd /data/dbus-huaweisun2000-pvinverter
sh install.sh
```

Configure in GUI: **Settings → PV Inverters → Huawei SUN2000**

### Step 2: Install Additional Inverters

For each additional inverter, run:

```bash
cd /data/dbus-huaweisun2000-pvinverter
sh install-additional-inverter.sh <instance_number>
```

Examples:
```bash
# Install second inverter (instance #2)
sh install-additional-inverter.sh 2

# Install third inverter (instance #3)
sh install-additional-inverter.sh 3

# Install fourth inverter (instance #4)
sh install-additional-inverter.sh 4
```

The script will:
1. Create a dedicated service directory
2. Generate service run scripts with the correct instance ID
3. Create log directories
4. Add to `/data/rc.local` for reboot survival
5. Start the service automatically

### Step 3: Configure Each Instance

After installation, configure each inverter in the Venus OS GUI.

**For Instance 1:**
Navigate to: **Settings → PV Inverters → Huawei SUN2000**

**For Instance 2+:**
You need to add GUI entries (see GUI Setup below) or configure via command line.

#### Command Line Configuration

You can configure additional instances using `dbus` commands:

```bash
# Configure Instance #2
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusHost SetValue "192.168.200.2"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusPort SetValue 6607
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusUnit SetValue 0
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/CustomName SetValue "Inverter East"

# Configure Instance #3
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/ModbusHost SetValue "192.168.200.3"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/CustomName SetValue "Inverter West"
```

The service will automatically restart when settings change.

### Step 4: Set Up GUI (Optional)

To add GUI settings pages for additional instances:

```bash
cd /data/dbus-huaweisun2000-pvinverter

# Generate GUI files for instance #2
sh create-gui-for-instance.sh 2

# Generate GUI files for instance #3
sh create-gui-for-instance.sh 3
```

The script creates QML files and provides instructions for integrating them into the Venus OS GUI.

**Manual GUI Integration:**

For **GUI-v1 (Classic UI)**:
1. Copy the generated QML file:
   ```bash
   cp gui/PageSettingsHuaweiSUN2000_2.qml /opt/victronenergy/gui/qml/
   ```

2. Edit `/opt/victronenergy/gui/qml/PageSettingsFronius.qml` and add:
   ```qml
   MbSubMenu {
       description: qsTr("Huawei SUN2000 #2")
       subpage: Component { PageSettingsHuaweiSUN2000_2 {} }
   }
   ```

3. Restart GUI:
   ```bash
   svc -t /service/gui
   ```

For **GUI-v2 (New UI)**: Follow similar steps using the gui-v2 file.

## Verification

### Check Service Status

```bash
# Check all Huawei services
svstat /service/dbus-huaweisun2000-pvinverter*

# Check specific instance
svstat /service/dbus-huaweisun2000-pvinverter-2
```

Expected output: `up (pid XXXX) XXX seconds`

### Check DBus Services

```bash
# List all Huawei inverter services
dbus -y | grep sun2000

# Check data from specific instance
dbus -y com.victronenergy.pvinverter.sun2000_1 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_2 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_3 /Ac/Power GetValue
```

### View Logs

```bash
# Instance #1 (main)
tail -f /var/log/dbus-huaweisun2000/current | tai64nlocal

# Instance #2
tail -f /var/log/dbus-huaweisun2000-2/current | tai64nlocal

# Instance #3
tail -f /var/log/dbus-huaweisun2000-3/current | tai64nlocal
```

## Network Configuration

Each inverter must have a **unique IP address** accessible from Venus OS.

### Common Scenarios

**Scenario 1: All inverters on same network**
- Inverter 1: 192.168.200.1
- Inverter 2: 192.168.200.2
- Inverter 3: 192.168.200.3
- Venus OS connects to your local network

**Scenario 2: Using inverter WiFi access points**
- Each inverter creates its own WiFi AP
- You can only connect to one AP at a time
- Solution: Use a WiFi router and configure all inverters to connect as clients
- Or use Ethernet connections to each inverter

**Scenario 3: Using Modbus RTU/RS485 (not supported yet)**
- Current driver only supports Modbus TCP
- Each inverter needs unique IP for TCP connection

### Setting Unique IPs on Huawei Inverters

Use the Huawei FusionSolar app or web interface:
1. Connect to inverter WiFi
2. Open browser to 192.168.200.1
3. Login (installer credentials)
4. Go to Communication Settings → Modbus TCP
5. Set unique IP for each inverter
6. Note: May require connecting via app for some models

## VRM Portal Integration

All instances will appear separately in VRM Portal:
- Each inverter shows up as a distinct PV inverter
- Historical data logged independently
- Power totals are summed in system overview
- Each inverter can be named uniquely (via CustomName setting)

**Portal View:**
```
PV Inverters:
├─ Huawei SUN2000 #1 (Inverter East)    - 5000W
├─ Huawei SUN2000 #2 (Inverter West)    - 4500W
└─ Huawei SUN2000 #3 (Inverter Garage)  - 3000W
Total PV Production: 12500W
```

## Troubleshooting

### Service Won't Start

Check logs for error messages:
```bash
tail -f /var/log/dbus-huaweisun2000-<instance>/current | tai64nlocal
```

Common issues:
- **Invalid IP address**: Check ModbusHost setting
- **Connection refused**: Verify inverter Modbus TCP is enabled
- **Duplicate VRM instance**: Each instance must have unique ID

### Configuration Not Saved

Ensure settings path is correct:
```bash
# List all Huawei settings
dbus -y com.victronenergy.settings / GetValue | grep HuaweiSUN2000
```

### DBus Service Not Appearing

1. Check service is running: `svstat /service/dbus-huaweisun2000-pvinverter-<instance>`
2. Check for errors in logs
3. Verify Python script can run manually:
   ```bash
   python /data/dbus-huaweisun2000-pvinverter/dbus-huaweisun2000-pvinverter.py <instance_id>
   ```

### Inverters Conflict

If two instances try to use the same IP:
- Both will attempt connections
- Data may be corrupted or inconsistent
- Check ModbusHost settings for each instance

### Smart Meter Data

Each inverter can have its own smart meter (DTSU666-H) connected:
- Meter data is reported per-inverter
- Grid data shows up under each service:
  - `com.victronenergy.pvinverter.sun2000_1/Meter/Power`
  - `com.victronenergy.pvinverter.sun2000_2/Meter/Power`
- Total grid power is summed by Venus OS

## Removing an Instance

To remove an additional instance:

```bash
# Stop the service
svc -d /service/dbus-huaweisun2000-pvinverter-<instance>

# Remove symlink
rm /service/dbus-huaweisun2000-pvinverter-<instance>

# Remove service directory
rm -rf /data/dbus-huaweisun2000-pvinverter/service-<instance>

# Remove from rc.local
nano /data/rc.local
# Delete the line: /data/dbus-huaweisun2000-pvinverter/install-additional-inverter.sh <instance>

# Remove settings (optional - will auto-cleanup)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_<instance> DeleteNode

# Restart GUI if needed
svc -t /service/gui
```

## Advanced Configuration

### Custom Service Names

You can modify the service name in `install-additional-inverter.sh` if needed, but this is not recommended for normal use.

### Running Test Script

Test connectivity for a specific instance:
```bash
python /data/dbus-huaweisun2000-pvinverter/connector_modbus.py <instance_id>
```

### Manual Service Creation

If the script doesn't work, you can manually create services by copying the pattern from `service-<instance>/run`.

## Performance Considerations

- Each instance polls its inverter independently
- Default poll interval: 1000ms (1 second)
- Multiple instances increase CPU usage slightly
- Network traffic scales linearly with instance count
- VRM uploads remain every ~15 minutes per device

**Recommendations:**
- Up to 5 inverters: No issues on Cerbo GX or similar
- 6-10 inverters: Consider increasing UpdateTimeMS to 2000-5000ms
- 10+ inverters: May need more powerful Venus OS device

## Example: 3-Inverter System

Complete setup for a system with 3 inverters:

```bash
# Install instance 1 (already done via main install.sh)
# Configure: Settings → PV Inverters → Huawei SUN2000

# Install instance 2
cd /data/dbus-huaweisun2000-pvinverter
sh install-additional-inverter.sh 2

# Configure instance 2
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusHost SetValue "192.168.1.12"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/CustomName SetValue "Roof East"

# Install instance 3
sh install-additional-inverter.sh 3

# Configure instance 3
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/ModbusHost SetValue "192.168.1.13"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/CustomName SetValue "Roof West"

# Verify all running
svstat /service/dbus-huaweisun2000-pvinverter*

# Check data
dbus -y com.victronenergy.pvinverter.sun2000_1 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_2 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_3 /Ac/Power GetValue
```

## Limitations

- Maximum 99 instances (practical limit ~10)
- Each inverter needs unique IP address
- GUI integration requires manual steps for instance 2+
- No auto-discovery of inverters

## Support

For issues with multi-inverter setup:
1. Check logs for each instance
2. Verify network connectivity to each inverter
3. Ensure unique IP addresses
4. Check VRM instance IDs are unique
5. Open GitHub issue with logs if problems persist
