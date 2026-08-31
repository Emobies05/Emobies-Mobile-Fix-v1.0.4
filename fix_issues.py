import os

PROJECT = os.path.expanduser("~/Emobies-Mobile-Fix-v1.0.4")

theme_path = os.path.join(PROJECT, "lib/config/theme.dart")
gradle_path = os.path.join(PROJECT, "android/app/build.gradle")

def backup(path):
    bak = path + ".bak"
    with open(path, "r") as f:
        content = f.read()
    with open(bak, "w") as f:
        f.write(content)
    return content

# Fix theme.dart
if os.path.exists(theme_path):
    content = backup(theme_path)
    new_content = content.replace("CardTheme(", "CardThemeData(").replace("DialogTheme(", "DialogThemeData(")
    with open(theme_path, "w") as f:
        f.write(new_content)
    print(f"Fixed: {theme_path}")
    print(f"  CardTheme( -> CardThemeData(: {content.count('CardTheme(')} occurrence(s)")
    print(f"  DialogTheme( -> DialogThemeData(: {content.count('DialogTheme(')} occurrence(s)")
else:
    print(f"NOT FOUND: {theme_path}")

# Fix build.gradle
if os.path.exists(gradle_path):
    content = backup(gradle_path)
    new_content = content.replace("compileSdk = 35", "compileSdk = 36").replace("targetSdk = 35", "targetSdk = 36")
    with open(gradle_path, "w") as f:
        f.write(new_content)
    print(f"Fixed: {gradle_path}")
else:
    print(f"NOT FOUND: {gradle_path}")

print("\nDone. .bak backups created alongside originals.")
