#!/usr/bin/env python3
import os
import zipfile
import multiprocessing
from concurrent.futures import ProcessPoolExecutor

BASE = "/Volumes/NFS/chartmaker"

# Configuration - update these paths

# Actual pixel data always comes from here (post-merge, post-quantize).
SOURCE_DIRS = {
    "Sectional": os.path.join(BASE, "chartmaker", "workarea", "Sectional", "6_quantized"),
    "Terminal": os.path.join(BASE, "chartmaker", "workarea", "Terminal", "6_quantized"),
    "Enroute_Low": os.path.join(BASE, "chartmaker", "workarea", "Enroute_Low", "6_quantized"),
    "Grand_Canyon": os.path.join(BASE, "chartmaker", "workarea", "Grand_Canyon", "6_quantized"),
}

# 4_tiled is used only as a live tile-membership source -- which z/x/y tiles
# belong to which named area -- since it's still organized per-area (city
# name) from before mergetiles.pl combined everything into one tree. Reading
# this directly means the zip script always matches whatever actually got
# built, instead of a hand-maintained JSON manifest that can silently drift
# out of sync (missing/renamed areas) from one build cycle to the next.
TILED_DIRS = {
    "Sectional": os.path.join(BASE, "chartmaker", "workarea", "Sectional", "4_tiled"),
    "Terminal": os.path.join(BASE, "chartmaker", "workarea", "Terminal", "4_tiled"),
}

ZIP_DIRS = {
    "Sectional": os.path.join(BASE, "metarmap", "zips", "Sectional"),
    "Terminal": os.path.join(BASE, "metarmap", "zips", "Terminal"),
    "Enroute_Low": os.path.join(BASE, "metarmap", "zips", "Enroute_Low"),
    "Grand_Canyon": os.path.join(BASE, "metarmap", "zips", "Terminal"),
}

ZOOM_LEVEL = {
    "Sectional": ["8", "9", "10", "11"],
    "Terminal": ["10", "11"],
    "Enroute_Low": ["8", "9", "10", "11"],
    "Grand_Canyon": ["10", "11"],
}


def format_area_name(raw_name):
    """
    4_tiled folder names are all-lowercase with underscores (chartmaker's own
    normalizeFileName() convention, e.g. "dallas_ft_worth"). Zip file names
    need to match the Title_Case_With_Underscores convention used everywhere
    else (terminals.txt, the app's catalog, etc.), e.g. "Dallas_Ft_Worth".
    """
    return "_".join(word.capitalize() for word in raw_name.split("_"))


def area_tile_list(area_folder):
    """Every 'z/x/y.png' path found under a single 4_tiled/{area}/ folder."""
    tiles = []
    for root, _dirs, files in os.walk(area_folder):
        for f in files:
            if f.endswith(".png"):
                rel = os.path.relpath(os.path.join(root, f), area_folder)
                tiles.append(rel.replace(os.sep, "/"))
    return tiles


def build_area_map(chart_type):
    """area name -> list of 'z/x/y.png' tile paths, read live from 4_tiled."""
    base = TILED_DIRS[chart_type]
    areas = {}
    for entry in sorted(os.listdir(base)):
        area_path = os.path.join(base, entry)
        if os.path.isdir(area_path):
            areas[entry] = area_tile_list(area_path)
    return areas


def process_chart(base_name, tile_names, chart_type):
    """
    Creates a zip for one area, pulling only tiles within the allowed zoom
    levels. tile_names is a membership list (which z/x/y belong to this
    area) -- the actual bytes always come from SOURCE_DIRS[chart_type], which
    may be a different chart product than whatever folder tile_names came
    from (see Enroute_Low in main()).
    """
    allowed_zooms = set(ZOOM_LEVEL[chart_type])
    zip_path = os.path.join(ZIP_DIRS[chart_type], f"{format_area_name(base_name)}.zip")
    source_dir = SOURCE_DIRS[chart_type]
    missing = 0

    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for tile in tile_names:
            zoom = tile.split("/", 1)[0]
            if zoom not in allowed_zooms:
                continue

            tile_path = os.path.join(source_dir, tile)
            if os.path.exists(tile_path):
                zf.write(tile_path, arcname=tile)
            else:
                missing += 1

    suffix = f" ({missing} tiles missing from source)" if missing else ""
    print(f"Created {zip_path}{suffix}")


def process_area_map(area_map, chart_type):
    """Builds one zip per area in area_map, in parallel."""
    if not area_map:
        print(f"No areas to process for {chart_type}, skipping.")
        return
    num_workers = min(multiprocessing.cpu_count(), len(area_map))
    print(f"Processing {chart_type} charts using {num_workers} workers...")

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        futures = [
            executor.submit(process_chart, base_name, tile_names, chart_type)
            for base_name, tile_names in area_map.items()
        ]
        for future in futures:
            try:
                future.result()
            except Exception as e:
                print(f"Error processing {chart_type} chart: {e}")


def zip_grand_canyon():
    """
    Grand Canyon isn't split by area like Sectional/Terminal -- it's one
    small, self-contained chart -- so this just zips the whole merged/
    quantized tree directly, zoom-filtered, no per-area membership needed.
    """
    allowed_zooms = set(ZOOM_LEVEL["Grand_Canyon"])
    source_dir = SOURCE_DIRS["Grand_Canyon"]
    zip_path = os.path.join(ZIP_DIRS["Grand_Canyon"], "Grand_Canyon.zip")

    if not os.path.isdir(source_dir):
        print(f"Skipping Grand_Canyon: source dir '{source_dir}' not found.")
        return

    count = 0
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for zoom in sorted(os.listdir(source_dir)):
            if zoom not in allowed_zooms:
                continue
            zoom_dir = os.path.join(source_dir, zoom)
            if not os.path.isdir(zoom_dir):
                continue
            for root, _dirs, files in os.walk(zoom_dir):
                for f in files:
                    if not f.endswith(".png"):
                        continue
                    full = os.path.join(root, f)
                    arcname = os.path.relpath(full, source_dir)
                    zf.write(full, arcname=arcname)
                    count += 1

    print(f"Created {zip_path} ({count} tiles)")


def main():
    for dir_path in ZIP_DIRS.values():
        os.makedirs(dir_path, exist_ok=True)

    print("Reading Sectional tile membership from 4_tiled...")
    sectional_areas = build_area_map("Sectional")
    print(f"  {len(sectional_areas)} areas found")

    print("Reading Terminal tile membership from 4_tiled...")
    terminal_areas = build_area_map("Terminal")
    print(f"  {len(terminal_areas)} areas found")

    process_area_map(sectional_areas, "Sectional")
    process_area_map(terminal_areas, "Terminal")

    # Enroute_Low's own 4_tiled is organized by IFR chart panel number
    # (enr_l01, enr_l06n, ...), not by city, so there's no per-city membership
    # list to read from it directly. Tile addressing is purely geographic
    # though (a given z/x/y means the same real-world location regardless of
    # chart product), so Sectional's city membership is reused here, just
    # pointed at Enroute_Low's own merged/quantized pixels and zoom range.
    print("Building Enroute_Low zips from Sectional's city membership...")
    process_area_map(sectional_areas, "Enroute_Low")

    zip_grand_canyon()


if __name__ == "__main__":
    main()
