import os

PROJECT = os.path.expanduser("~/Emobies-Mobile-Fix-v1.0.4/.github/workflows")

files_and_patterns = [
    (os.path.join(PROJECT, "build.yml"), "flutter build appbundle --release --verbose || true",
     "flutter build appbundle --release --verbose --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} || true"),
    (os.path.join(PROJECT, "emobies_build.yml"), "flutter build apk --release",
     "flutter build apk --release --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}"),
    (os.path.join(PROJECT, "emobies_build.yml"), "flutter build appbundle --release",
     "flutter build appbundle --release --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}"),
]

for path, old, new in files_and_patterns:
    if not os.path.exists(path):
        print(f"NOT FOUND: {path}")
        continue
    with open(path, "r") as f:
        content = f.read()
    if old not in content:
        print(f"Pattern not found in {path}: {old[:50]}...")
        continue
    bak = path + ".bak"
    if not os.path.exists(bak):
        with open(bak, "w") as f:
            f.write(content)
    new_content = content.replace(old, new)
    with open(path, "w") as f:
        f.write(new_content)
    print(f"Fixed in {os.path.basename(path)}: {old[:40]}...")

print("\nDone.")
