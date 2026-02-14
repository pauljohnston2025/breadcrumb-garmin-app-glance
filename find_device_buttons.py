#!/usr/bin/env python3
import json
from pathlib import Path

# Your specific product list
TARGET_IDS = {
    "approachs50", "approachs7042mm", "approachs7047mm", "d2airx10", "d2mach1", 
    "d2mach2", "descentg2", "descentmk343mm", "descentmk351mm", "edge1040", 
    "edge1050", "edge540", "edge550", "edge840", "edge850", "edgeexplore2", 
    "edgemtb", "enduro3", "epix2", "epix2pro42mm", "epix2pro47mm", "epix2pro51mm", 
    "etrextouch", "fenix7", "fenix7pro", "fenix7pronowifi", "fenix7s", "fenix7spro", 
    "fenix7x", "fenix7xpro", "fenix7xpronowifi", "fenix843mm", "fenix847mm", 
    "fenix8pro47mm", "fenix8solar47mm", "fenix8solar51mm", "fenixe", "fr165", 
    "fr165m", "fr255", "fr255m", "fr255s", "fr255sm", "fr265", "fr265s", 
    "fr57042mm", "fr57047mm", "fr955", "fr965", "fr970", "gpsmaph1", 
    "instinct3amoled45mm", "instinct3amoled50mm", "instinctcrossoveramoled", 
    "marq2", "marq2aviator", "system8preview", "venu2", "venu2plus", "venu2s", 
    "venu3", "venu3s", "venu441mm", "venu445mm", "venusq2", "venusq2m", 
    "venux1", "vivoactive5", "vivoactive6"
}

def parse_garmin_simulators(root_dir='.'):
    pathlist = Path(root_dir).rglob('simulator.json')
    categories = {"5-BUTTON": [], "2-BUTTON": [], "UNKNOWN": []}

    for path in pathlist:
        device_id = path.parts[-2]
        if device_id not in TARGET_IDS:
            continue

        try:
            with open(path, 'r') as f:
                data = json.load(f)
            
            keys = data.get('keys', [])
            physical_keys = []
            seen_locations = set()

            for k in keys:
                if k.get('isHold') is True: continue
                loc = k.get('location', {})
                coords = (loc.get('x'), loc.get('y'))
                if coords in seen_locations: continue
                seen_locations.add(coords)
                physical_keys.append(k)

            phys_count = len(physical_keys)
            all_behaviors = [str(k.get('behavior')).lower() for k in keys]
            
            # Check for navigation behaviors
            has_up = any('previouspage' in b for b in all_behaviors)
            has_down = any('nextpage' in b for b in all_behaviors)

            # Side check (threshold adjusted for high-res)
            left_phys = [k for k in physical_keys if (k.get('location', {}).get('x') or 0) < 150]

            # Logic: 5-button watches often only show 4 keys (missing Light)
            # but they will have 2 keys on the left (Up/Down) plus the missing Light.
            is_5_btn = (has_up and has_down and len(left_phys) >= 2)
            is_2_btn = (phys_count == 2 and not has_up)

            if is_5_btn:
                categories["5-BUTTON"].append(device_id)
            elif is_2_btn:
                categories["2-BUTTON"].append(device_id)
            else:
                categories["UNKNOWN"].append(f"{device_id} ({phys_count} physical buttons)")

        except Exception:
            continue

    for cat, devices in categories.items():
        print(f"\n=== {cat} ({len(devices)}) ===")
        print(", ".join(sorted(devices)) if devices else "None")

if __name__ == "__main__":
    parse_garmin_simulators()