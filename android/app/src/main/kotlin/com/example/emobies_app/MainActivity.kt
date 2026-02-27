- name: Android 15 & Signing Inject
        run: |
          # പാക്കേജ് നെയിം പ്ലേ സ്റ്റോർ ഐഡിയുമായി മാച്ച് ചെയ്യുന്നു
          mkdir -p android/app/src/main/kotlin/com/nxtbit/emobies_24
          cat > android/app/src/main/kotlin/com/nxtbit/emobies_24/MainActivity.kt << 'EOF'
          package com.nxtbit.emobies_24
          import io.flutter.embedding.android.FlutterFragmentActivity
          class MainActivity: FlutterFragmentActivity()
          EOF
