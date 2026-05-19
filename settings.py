#!/usr/bin/env python3

# flake8 --ignore E501,E402 settings.py

import dbus
import logging
import os
import sys

sys.path.insert(1, os.path.join(os.path.dirname(__file__), '/opt/victronenergy/dbus-systemcalc-py/ext/velib_python'))
from settingsdevice import SettingsDevice


class SystemBus(dbus.bus.BusConnection):
    def __new__(cls):
        return dbus.bus.BusConnection.__new__(cls, dbus.bus.BusConnection.TYPE_SYSTEM)


class SessionBus(dbus.bus.BusConnection):
    def __new__(cls):
        return dbus.bus.BusConnection.__new__(cls, dbus.bus.BusConnection.TYPE_SESSION)


class HuaweiSUN2000Settings(object):

    def __init__(self, instance_id=1):
        self.instance_id = instance_id
        # Use instance-specific paths to allow multiple inverters
        settings_prefix = f"/Settings/HuaweiSUN2000_{instance_id}" if instance_id > 1 else "/Settings/HuaweiSUN2000"
        device_prefix = f"/Settings/Devices/HuaweiSUN2000_{instance_id}" if instance_id > 1 else "/Settings/Devices/HuaweiSUN2000"

        # path, default value, min, max, logging silent or not
        supported_settings = {
            "modbus_host": [f"{settings_prefix}/ModbusHost", "192.168.200.1", "", "", 0],
            "modbus_port": [f"{settings_prefix}/ModbusPort", 6607, 1, 65536, 0],
            "modbus_unit": [f"{settings_prefix}/ModbusUnit", 0, 0, 247, 0],
            "custom_name": [f"{settings_prefix}/CustomName", f"Huawei SUN2000 #{instance_id}", "", "", 0],
            "position": [f"{settings_prefix}/Position", 1, 0, 2, 0],
            "update_time_ms": [f"{settings_prefix}/UpdateTimeMS", 1000, 100, 10000000, 0],
            "power_correction_factor": [f"{settings_prefix}/PowerCorrectionFactor", 0.995, 0.001, 100.0, 0],
            # VRM instance uses the instance_id to ensure unique values
            "vrm_instance": [f"{device_prefix}/ClassAndVrmInstance", f"pvinverter:{instance_id}", "", "", 0],
        }
        self.dbus_conn = self._dbusconnection()
        self.settings = SettingsDevice(bus=self.dbus_conn, supportedSettings=supported_settings, eventCallback=self._handle_changed_setting)

    def _dbusconnection(self):
        return SessionBus() if "DBUS_SESSION_BUS_ADDRESS" in os.environ else SystemBus()

    def _handle_changed_setting(self, setting, oldvalue, newvalue):
        logging.info(f"setting changed, setting: {setting}, old: {oldvalue}, new: {newvalue}")
        logging.info("Exiting due to new setting. The service will get restarted and pick up the new setting.")
        # I consider this to be a bit of a hack, but it works for now. If there are config changes, the
        # service exits and gets restarted and thus picks up the new settings values.
        sys.exit(0)

    def get(self, setting):
        return self.settings[setting]

    def set(self, setting, value):
        self.settings[setting] = value

    def get_vrm_instance(self):
        return int(self.settings["vrm_instance"].split(":")[1])
