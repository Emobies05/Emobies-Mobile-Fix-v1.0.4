#!/data/data/com.termux/files/usr/bin/python3
import os
import re

PROJECT = os.path.expanduser("~/Emobies-Mobile-Fix-v1.0.4")

def find_files(root, name_patterns):
    matches = []
    for dirpath, _, files in os.walk(root):
        if "/build/" in dirpath or "/.git/" in dirpath:
            continue
        for f in files:
            for pat in name_patterns:
                if re.search(pat, f):
                    matches.append(os.path.join(dirpath, f))
    return matches

print(f"Scanning project: {PROJECT}\n")

dart_files = find_files(PROJECT, [r"\.dart$"])
theme_hits = []
for fpath in dart_files:
    try:
        with open(fpath, "r", errors="ignore") as fh:
            content = fh.read()
    except Exception:
        continue
    if "CardTheme(" in content or "DialogTheme(" in content:
        lines = content.splitlines()
        for i, line in enumerate(lines, 1):
            if "CardTheme(" in line or "DialogTheme(" in line:
                theme_hits.append((fpath, i, line.strip()))

print("=== CardTheme / DialogTheme usages ===")
if theme_hits:
    for fpath, lineno, line in theme_hits:
        print(f"{fpath}:{lineno}: {line}")
else:
    print("None found.")

pubspec_path = os.path.join(PROJECT, "pubspec.yaml")
print("\n=== pubspec.yaml SDK constraints ===")
if os.path.exists(pubspec_path):
    with open(pubspec_path, "r", errors="ignore") as fh:
        for i, line in enumerate(fh, 1):
            if "sdk:" in line or "flutter:" in line.lower():
                print(f"{i}: {line.rstrip()}")
else:
    print("pubspec.yaml not found!")

gradle_candidates = find_files(os.path.join(PROJECT, "android"), [r"build\.gradle(\.kts)?$"])
print("\n=== build.gradle compileSdk/targetSdk/minSdk ===")
for gpath in gradle_candidates:
    if "/app/" not in gpath:
        continue
    with open(gpath, "r", errors="ignore") as fh:
        for i, line in enumerate(fh, 1):
            if re.search(r"(compileSdk|targetSdk|minSdk)", line):
                print(f"{gpath}:{i}: {line.strip()}")

print("\nScan complete. Send me this full output.")
