# SmartLogger3000 Compatibility

## Overview

The Huawei SmartLogger3000 is a data logger and monitoring device designed for commercial and utility-scale PV installations. This document addresses compatibility with the dbus-huaweisun2000-pvinverter driver.

## Current Status: Unknown / Untested

**The driver has NOT been tested with SmartLogger3000.** Here's what we know:

### What is SmartLogger3000?

SmartLogger3000 is Huawei's industrial-grade data logger that:
- Collects data from multiple inverters
- Provides centralized monitoring
- Supports Modbus RTU/TCP communication
- Used in commercial solar installations
- Replaces individual inverter connections

### Theoretical Compatibility

The driver **might** work with SmartLogger3000 if:

1. **SmartLogger3000 exposes Modbus TCP interface**
   - Current driver uses Modbus TCP protocol
   - Default port: 6607
   - Same register map as direct inverter connection

2. **Register addresses are identical**
   - SmartLogger3000 must expose same Modbus registers
   - Registers defined in `sun2000_modbus/registers.py`:
     - `InverterEquipmentRegister` - inverter data
     - `MeterEquipmentRegister` - smart meter data
   - Register numbers must match exactly

3. **Multiple inverter handling**
   - SmartLogger3000 aggregates multiple inverters
   - Unknown if it exposes per-inverter data or aggregated data
   - May require different approach than direct connection

### Known Differences

**SmartLogger3000** vs **Direct Inverter Connection**:

| Feature | Direct Inverter | SmartLogger3000 |
|---------|----------------|-----------------|
| Connection | Direct Modbus TCP | Via data logger |
| Typical Use | Residential (1-3 inverters) | Commercial (10+ inverters) |
| Modbus Port | 6607 | Usually 502 or 6607 |
| Register Map | Standard Sun2000 | Possibly modified |
| Per-inverter data | Yes | Unknown |
| Aggregated data | No | Likely |

### Testing Required

To determine compatibility, someone with SmartLogger3000 access needs to:

1. **Verify Modbus TCP Access**
   ```bash
   # Test basic TCP connection
   telnet <smartlogger-ip> 6607
   # or
   telnet <smartlogger-ip> 502
   ```

2. **Check Register Mapping**
   - Use Modbus testing tool (e.g., `modpoll` or similar)
   - Verify register addresses match `sun2000_modbus/registers.py`
   - Test reading key registers:
     - 30000: Model name
     - 32016: Active power
     - 32064: Total energy

3. **Test Driver Connection**
   ```bash
   # Try connecting to SmartLogger3000
   cd /data/dbus-huaweisun2000-pvinverter

   # Edit config temporarily (or use GUI)
   dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusHost SetValue "<smartlogger-ip>"
   dbus -y com.victronenergy.settings /Settings/HuaweiSUN2000/ModbusPort SetValue 6607

   # Restart service
   svc -d /service/dbus-huaweisun2000-pvinverter
   svc -u /service/dbus-huaweisun2000-pvinverter

   # Check logs
   tail -f /var/log/dbus-huaweisun2000/current | tai64nlocal
   ```

4. **Verify Data**
   ```bash
   # Check if data is being read
   dbus -y com.victronenergy.pvinverter.sun2000 /Ac/Power GetValue
   dbus -y com.victronenergy.pvinverter.sun2000 /Ac/Energy/Forward GetValue
   ```

## Possible Scenarios

### Scenario 1: Direct Compatibility ✓

If SmartLogger3000 uses identical Modbus register map:
- Driver should work without modifications
- May expose aggregated data from all connected inverters
- Single DBus service represents all inverters combined

**Action**: No changes needed, just configure IP address

### Scenario 2: Different Port

If SmartLogger3000 uses different Modbus port (e.g., 502 instead of 6607):
- Change ModbusPort setting in Venus OS GUI
- No code changes required

**Action**: Configure port in settings

### Scenario 3: Different Register Map

If SmartLogger3000 uses different register addresses:
- Driver needs modification to support alternate register map
- Would require:
  1. Documentation of SmartLogger3000 register map
  2. New register definitions in `sun2000_modbus/registers.py`
  3. Logic to detect SmartLogger vs direct inverter
  4. Conditional register reading

**Action**: Code modifications required (see Implementation Plan below)

### Scenario 4: Multiple Inverter Exposure

If SmartLogger3000 exposes individual inverters via Modbus:
- May use different Modbus Unit IDs for each inverter
- Could use multi-inverter support (instance 1, 2, 3...)
- Each instance points to same IP but different Unit ID

**Action**: Use multi-inverter installation with different ModbusUnit values

### Scenario 5: Incompatible

If SmartLogger3000:
- Uses proprietary protocol
- Doesn't support Modbus TCP
- Has completely different register structure
- Requires authentication not supported

**Action**: Driver cannot support, would need complete rewrite

## Implementation Plan (If Compatible)

If testing shows SmartLogger3000 uses same register map:

### No Changes Needed
1. Configure SmartLogger3000 IP in GUI
2. Verify Modbus TCP is enabled on SmartLogger
3. Test and report results

### If Different Port or Unit ID
1. Adjust settings:
   - ModbusPort: Change from 6607 to 502 (or other)
   - ModbusUnit: Try 0, 1, or other unit IDs
2. Test connection

### If Different Register Map Needed

Add SmartLogger3000 register support:

```python
# In sun2000_modbus/registers.py
class SmartLogger3000Register(InverterEquipmentRegister):
    """Register definitions for SmartLogger3000"""
    # Add specific register addresses if different
    pass
```

Modify driver to detect device type:
```python
# In dbus-huaweisun2000-pvinverter.py
# Detect if connected to SmartLogger vs inverter
device_model = modbus.getStaticData()['Model']
if 'SmartLogger' in device_model:
    # Use SmartLogger register map
    pass
else:
    # Use standard inverter register map
    pass
```

## How to Contribute SmartLogger3000 Support

If you have access to SmartLogger3000:

1. **Test Current Driver**
   - Follow testing steps above
   - Document what works and what doesn't

2. **Gather Information**
   - SmartLogger3000 model number
   - Firmware version
   - Modbus TCP configuration
   - Register map documentation (if available)

3. **Capture Register Data**
   - Use Modbus testing tools
   - Read registers 30000-33000
   - Document which registers return data
   - Compare with current register definitions

4. **Report Results**
   - Open GitHub issue with title: "SmartLogger3000 Compatibility Test Results"
   - Include:
     - Model and firmware version
     - Connection details (IP, port, unit ID)
     - Which registers work/don't work
     - Any error messages from driver
     - Screenshots of successful/failed data

5. **Share Register Map**
   - If you have official Modbus register documentation
   - Or reverse-engineered register map
   - This is most valuable for adding support

## Alternative: Huawei FusionSolar API

If SmartLogger3000 Modbus is incompatible, consider:

**Huawei FusionSolar Cloud API**:
- SmartLogger3000 typically uploads data to FusionSolar cloud
- Cloud has API for data access
- Could write alternative driver using cloud API
- Requires internet connection
- May have data delays

This would be a **different driver** not based on Modbus.

## Known Working Devices

For reference, these devices are confirmed working:

✅ **Huawei SUN2000 Series (Direct Connection)**:
- SUN2000-3KTL-L1
- SUN2000-4KTL-L1
- SUN2000-5KTL-L1
- SUN2000-6KTL-M1
- SUN2000-8KTL-M1
- SUN2000-10KTL-M1
- Other Sun2000 models (likely compatible)

✅ **Smart Meters** (connected via RS485 to inverter):
- DTSU666-H
- DDSU666-H

❓ **Unknown/Untested**:
- SmartLogger3000
- SmartLogger1000
- SmartLogger2000
- Other Huawei data loggers

## Summary

**SmartLogger3000 compatibility is UNKNOWN and UNTESTED.**

The driver:
- ✅ Supports direct connection to Huawei SUN2000 inverters
- ✅ Supports smart meters via RS485
- ✅ Supports multiple inverters (direct connections)
- ❓ May support SmartLogger3000 if register map is identical
- ❌ Has not been tested with any SmartLogger devices

**We welcome testing and feedback from users with SmartLogger3000!**

If you test this, please report your findings on GitHub so we can update this documentation and add support if possible.

## Resources

- Huawei SUN2000 Modbus Interface Documentation
- SmartLogger3000 Manual (check Modbus section)
- Huawei FusionSolar Portal: https://www.solarman.cn/
- GitHub Issues: Report SmartLogger3000 test results

## Contact

For SmartLogger3000 compatibility questions:
- Open a GitHub issue
- Provide as much detail as possible
- Include logs and connection details
- We'll work with you to add support if feasible
