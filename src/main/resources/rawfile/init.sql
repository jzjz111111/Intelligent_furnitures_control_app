INSERT INTO Zone (name, location, note, created_at) VALUES ('A区大棚', '东侧', '草莓', strftime('%s','now'));
INSERT INTO Device (zone_id, device_type_id, name, sn, status)
VALUES (1, (SELECT id FROM DeviceType WHERE code='VALVE_MAIN'), '主阀门1:1', 'VALVE-0001', 'online');
INSERT INTO Rule (zone_id, sensor_metric, operator, threshold_low, action, target_device_id, duration_sec, priority, enabled)
VALUES (1, 'soil_moisture', '<', 30.0, 'open_valve', (SELECT id FROM Device WHERE sn='VALVE-0001'), 300, 10, 1);