# SSH Configuration Guide for Huawei SUN2000 Inverters

This guide shows you how to configure Huawei SUN2000 inverter instances directly from SSH on your Venus OS device.

## Prerequisites

- SSH access to your Venus OS device
- Driver installed (see main README.md)
- Inverter IP address(es)

## Quick Start

### Configuring Instance #1 (Main Inverter)

If you installed the driver with the main `install.sh`, you have instance #1. Configure it via SSH:

```bash
# SSH into your Venus OS device
ssh root@<venus-os-ip>

# Set the inverter IP address (required)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "192.168.200.1"

# Set Modbus port (optional, default is 6607)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusPort SetValue 6607

# Set Modbus unit ID (optional, default is 0)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusUnit SetValue 0

# Set custom name (optional)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/CustomName SetValue "Solar Inverter"

# Set position (optional: 0=AC Input 1, 1=AC Output, 2=AC Input 2)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/Position SetValue 1

# Set update interval in milliseconds (optional, default is 1000)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/UpdateTimeMS SetValue 1000

# Set power correction factor (optional, default is 0.995)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/PowerCorrectionFactor SetValue 0.995
```

The service will automatically restart when you change settings.

### Configuring Additional Inverters (Instance #2, #3, etc.)

First, install the additional instance:

```bash
cd /data/dbus-huaweisun2000-pvinverter
sh install-additional-inverter.sh 2
```

Then configure it:

```bash
# Configure instance #2
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusHost SetValue "192.168.200.2"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusPort SetValue 6607
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusUnit SetValue 0
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/CustomName SetValue "East Roof"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/Position SetValue 1
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/UpdateTimeMS SetValue 1000
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/PowerCorrectionFactor SetValue 0.995

# Configure instance #3
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/ModbusHost SetValue "192.168.200.3"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/CustomName SetValue "West Roof"
# ... etc
```

**Pattern for any instance:**
- Replace `HuaweiSUN2000_X` with your instance number (e.g., `HuaweiSUN2000_4` for instance #4)
- Instance #1 uses `HuaweiSUN2000` without a number suffix

## Verification

### Check Current Settings

View your current configuration:

```bash
# View all settings for instance #1
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost GetValue
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusPort GetValue
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusUnit GetValue
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/CustomName GetValue

# View settings for instance #2
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusHost GetValue
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/CustomName GetValue

# List all Huawei settings
dbus -y com.victronenergy.settings / GetValue | grep HuaweiSUN2000
```

### Check Service Status

```bash
# Check if service is running
svstat /service/dbus-huaweisun2000-pvinverter        # Instance #1
svstat /service/dbus-huaweisun2000-pvinverter-2      # Instance #2
svstat /service/dbus-huaweisun2000-pvinverter-3      # Instance #3

# Should show: up (pid XXXX) XXX seconds
```

### Check Inverter Data

```bash
# Check if data is being read from inverter
dbus -y com.victronenergy.pvinverter.sun2000_1 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_1 /Ac/Energy/Forward GetValue

# For additional instances
dbus -y com.victronenergy.pvinverter.sun2000_2 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_3 /Ac/Power GetValue

# Check all available inverter services
dbus -y | grep pvinverter.sun2000
```

### View Logs

```bash
# View logs for instance #1
tail -f /var/log/dbus-huaweisun2000/current | tai64nlocal

# View logs for instance #2
tail -f /var/log/dbus-huaweisun2000-2/current | tai64nlocal

# Press Ctrl+C to exit log viewing
```

## Complete Configuration Example

Here's a complete example for setting up 3 inverters:

```bash
# SSH to Venus OS
ssh root@192.168.1.100

# Instance #1 is already installed by main install.sh
# Configure instance #1
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "192.168.200.1"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/CustomName SetValue "Main Inverter"

# Install and configure instance #2
cd /data/dbus-huaweisun2000-pvinverter
sh install-additional-inverter.sh 2
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusHost SetValue "192.168.200.2"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/CustomName SetValue "East Roof"

# Install and configure instance #3
sh install-additional-inverter.sh 3
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/ModbusHost SetValue "192.168.200.3"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/CustomName SetValue "West Roof"

# Verify all services are running
svstat /service/dbus-huaweisun2000-pvinverter*

# Check data from all inverters
dbus -y com.victronenergy.pvinverter.sun2000_1 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_2 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_3 /Ac/Power GetValue
```

## Common Configuration Scenarios

### Scenario 1: Single Inverter with Smart Meter

```bash
# Configure inverter
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "192.168.200.1"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/CustomName SetValue "Solar PV"

# No additional configuration needed for smart meter
# The driver automatically detects DTSU666-H/DDSU666-H meters

# Verify meter is detected
dbus -y com.victronenergy.pvinverter.sun2000_1 /Meter/Status GetValue
# Should return 1.0 if meter is connected
```

### Scenario 2: Multiple Inverters, All Same Network

```bash
# All inverters on 192.168.200.x network
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "192.168.200.1"

sh install-additional-inverter.sh 2
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusHost SetValue "192.168.200.2"

sh install-additional-inverter.sh 3
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/ModbusHost SetValue "192.168.200.3"
```

### Scenario 3: Inverters on Different Networks

```bash
# Inverter #1 on first network
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "192.168.1.50"

# Inverter #2 on second network
sh install-additional-inverter.sh 2
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusHost SetValue "10.0.0.100"

# Inverter #3 on third network
sh install-additional-inverter.sh 3
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/ModbusHost SetValue "172.16.0.10"
```

### Scenario 4: Using Non-Standard Modbus Port

```bash
# If your inverter uses a different port (e.g., 502)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "192.168.200.1"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusPort SetValue 502
```

## Troubleshooting via SSH

### Connection Issues

```bash
# Test network connectivity
ping 192.168.200.1

# Check if Modbus port is accessible
telnet 192.168.200.1 6607
# Press Ctrl+] then type 'quit' to exit

# View real-time logs to see connection errors
tail -f /var/log/dbus-huaweisun2000/current | tai64nlocal
```

### Service Not Running

```bash
# Check service status
svstat /service/dbus-huaweisun2000-pvinverter

# If down, check logs
tail -100 /var/log/dbus-huaweisun2000/current | tai64nlocal

# Restart service
svc -t /service/dbus-huaweisun2000-pvinverter

# Or stop and start
svc -d /service/dbus-huaweisun2000-pvinverter  # Stop
svc -u /service/dbus-huaweisun2000-pvinverter  # Start
```

### Incorrect Settings

```bash
# Reset to default IP
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "192.168.200.1"

# Reset port to default
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusPort SetValue 6607

# Reset unit ID to default
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusUnit SetValue 0

# Service will restart automatically after changing settings
```

### No Data from Inverter

```bash
# Check if service can connect
dbus -y com.victronenergy.pvinverter.sun2000_1 /Connected GetValue

# Check inverter serial number (verifies communication)
dbus -y com.victronenergy.pvinverter.sun2000_1 /Serial GetValue

# Check product name
dbus -y com.victronenergy.pvinverter.sun2000_1 /ProductName GetValue

# If all return nothing or errors, check logs
tail -f /var/log/dbus-huaweisun2000/current | tai64nlocal
```

## Advanced: Bulk Configuration Script

Create a script to configure multiple inverters quickly:

```bash
cat > /data/configure-inverters.sh << 'EOF'
#!/bin/bash

# Configure instance #1
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "192.168.200.1"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/CustomName SetValue "Inverter 1"

# Install and configure instance #2
cd /data/dbus-huaweisun2000-pvinverter
sh install-additional-inverter.sh 2
sleep 2
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/ModbusHost SetValue "192.168.200.2"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_2/CustomName SetValue "Inverter 2"

# Install and configure instance #3
sh install-additional-inverter.sh 3
sleep 2
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/ModbusHost SetValue "192.168.200.3"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000_3/CustomName SetValue "Inverter 3"

echo "Configuration complete!"
echo "Checking services..."
svstat /service/dbus-huaweisun2000-pvinverter*
EOF

# Make executable
chmod +x /data/configure-inverters.sh

# Run it
sh /data/configure-inverters.sh
```

## Settings Reference

### All Available Settings

| Setting | Path | Default | Description |
|---------|------|---------|-------------|
| Modbus Host | `/ModbusHost` | 192.168.200.1 | IP address of inverter |
| Modbus Port | `/ModbusPort` | 6607 | Modbus TCP port |
| Modbus Unit | `/ModbusUnit` | 0 | Modbus unit ID |
| Custom Name | `/CustomName` | Huawei SUN2000 #X | Display name |
| Position | `/Position` | 1 | 0=AC Input 1, 1=AC Output, 2=AC Input 2 |
| Update Time | `/UpdateTimeMS` | 1000 | Poll interval in milliseconds |
| Power Correction | `/PowerCorrectionFactor` | 0.995 | Power correction factor |

**Settings paths:**
- Instance #1: `/Settings/HuaweiSUN2000/<setting>`
- Instance #2: `/Settings/HuaweiSUN2000_2/<setting>`
- Instance #3: `/Settings/HuaweiSUN2000_3/<setting>`
- etc.

### Setting Value Types

```bash
# String values (IP, name)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "192.168.1.100"
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/CustomName SetValue "My Inverter"

# Integer values (port, unit, position, time)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusPort SetValue 6607
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusUnit SetValue 0
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/Position SetValue 1
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/UpdateTimeMS SetValue 2000

# Float values (correction factor)
dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/PowerCorrectionFactor SetValue 0.995
```

## Need GUI Configuration Instead?

If you prefer to use the Venus OS GUI for configuration:
- Instance #1 is automatically available in: **Settings → PV Inverters → Huawei SUN2000**
- For additional instances, see the GUI setup instructions in `MULTI-INVERTER.md`

## More Information

- **Multi-inverter setup:** See `MULTI-INVERTER.md`
- **SmartLogger3000 compatibility:** See `SMARTLOGGER3000.md`
- **General installation:** See `README.md`
- **Report issues:** Open an issue on GitHub

## Quick Reference Commands

```bash
# List all Huawei inverter services
dbus -y | grep sun2000

# List all Huawei settings
dbus -y com.victronenergy.settings / GetValue | grep HuaweiSUN2000

# Check all service statuses
svstat /service/dbus-huaweisun2000-pvinverter*

# View power from all inverters
dbus -y com.victronenergy.pvinverter.sun2000_1 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_2 /Ac/Power GetValue
dbus -y com.victronenergy.pvinverter.sun2000_3 /Ac/Power GetValue

# Restart all services
svc -t /service/dbus-huaweisun2000-pvinverter*
```
