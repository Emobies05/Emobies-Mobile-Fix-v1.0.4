import os

path = os.path.expanduser("~/Emobies-Mobile-Fix-v1.0.4/android/settings.gradle")

with open(path, "r") as f:
    content = f.read()

old = 'id "com.android.application" version "8.6.0" apply false'
new = 'id "com.android.application" version "8.9.1" apply false'

if old not in content:
    print("Pattern not found — checking current content around AGP line:")
    for line in content.splitlines():
        if "com.android.application" in line:
            print(line)
else:
    bak = path + ".bak"
    if not os.path.exists(bak):
        with open(bak, "w") as f:
            f.write(content)
    new_content = content.replace(old, new)
    with open(path, "w") as f:
        f.write(new_content)
    print("Fixed: AGP version 8.6.0 -> 8.9.1")

