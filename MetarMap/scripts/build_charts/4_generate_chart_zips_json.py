#!/usr/bin/env python3

import glob
import os
import json

BASE = "/Volumes/NFS/chartmaker"

MIN_SIZE_BYTES = 64 * 1024  # Minimum file size to include (64 KB)

# Chart configurations
CHARTS = {
    "Terminal": {
        "base_url": "https://regiruk.netlify.app/zips/Terminal/",
        "zip_dir": os.path.join(BASE, "metarmap", "zips", "Terminal"),
    },
    "Sectional": {
        "base_url": "https://regiruk.netlify.app/zips/Sectional/",
        "zip_dir": os.path.join(BASE, "metarmap", "zips", "Sectional"),
    },
    "Enroute_Low": {
        "base_url": "https://regiruk.netlify.app/zips/Enroute_Low/",
        "zip_dir": os.path.join(BASE, "metarmap", "zips", "Enroute_Low"),
    },
}


def get_file_size_mb(filepath):
    size_bytes = os.path.getsize(filepath)
    return round(size_bytes / (1024 * 1024), 2)


def process_chart(chart_name, config):
    print(f"🔍 Processing {chart_name}...")

    zip_dir = config["zip_dir"]
    base_url = config["base_url"]
    entries = []

    # Get the series (valid date) from metadata.json
    try:
        metadata_path = os.path.join(
            BASE,
            "chartmaker",
            "workarea",
            chart_name,
            "6_quantized",
            "metadata.json",
        )

        with open(metadata_path, "r") as meta_file:
            metadata = json.load(meta_file)
            series_valid = metadata.get("valid", "unknown")

    except Exception as e:
        print(f"⚠️ Could not read metadata for {chart_name}: {e}")
        series_valid = "unknown"

    # Take every zip actually present in the folder -- no separate allowlist
    # to keep in sync.
    if not os.path.isdir(zip_dir):
        print(f"❌ Skipping {chart_name}: zip_dir '{zip_dir}' not found.")
        return None

    found_files = sorted(
        os.path.basename(p) for p in glob.glob(os.path.join(zip_dir, "*.zip"))
    )

    for filename in found_files:
        filepath = os.path.join(zip_dir, filename)
        file_size = os.path.getsize(filepath)

        if file_size < MIN_SIZE_BYTES:
            print(
                f"🗑️ Deleting {filename} "
                f"(too small: {file_size} bytes)"
            )
            os.remove(filepath)
            continue

        entries.append({
            "name": os.path.splitext(filename)[0],
            "fileName": filename,
            "size": f"{get_file_size_mb(filepath)} MB",
            "url": f"{base_url}{filename}",
        })

    print(f"✅ Processed {chart_name}: {len(entries)} entries")

    return {
        "series": series_valid,
        "charts": entries,
    }


def main():
    all_charts = {}

    for chart_name, config in CHARTS.items():
        result = process_chart(chart_name, config)

        if result:
            all_charts[chart_name] = result

    output_path = os.path.join(
        BASE,
        "metarmap",
        "zips",
        "all_charts.json",
    )

    with open(output_path, "w") as f:
        json.dump(all_charts, f, indent=4)

    print(f"📦 Combined output written to {output_path}")


if __name__ == "__main__":
    main()
