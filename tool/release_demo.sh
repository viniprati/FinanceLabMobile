#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if [[ "$(git branch --show-current)" != "main" ]]; then
  echo "A publicação demo deve partir da branch main." >&2
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Faça commit de todas as alterações antes de publicar." >&2
  exit 1
fi

git fetch origin main --tags
if [[ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]]; then
  echo "A main local deve estar sincronizada com origin/main." >&2
  exit 1
fi

demo_tag="$(dart tool/check_version.dart --print-demo-tag)"
demo_build_number="${demo_tag##*.}"
demo_version_name="${demo_tag#v}"
demo_version_name="${demo_version_name%-demo.*}"
demo_repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"
if gh release view "$demo_tag" --repo "$demo_repo" >/dev/null 2>&1; then
  echo "A versão $demo_tag já está publicada." >&2
  exit 1
fi
if git rev-parse "$demo_tag^{commit}" >/dev/null 2>&1 &&
   [[ "$(git rev-parse "$demo_tag^{commit}")" != "$(git rev-parse HEAD)" ]]; then
  echo "A tag $demo_tag já aponta para outro commit." >&2
  exit 1
fi

flutter pub get
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build apk --debug

demo_apk_source="build/app/outputs/flutter-apk/app-debug.apk"
demo_apk_name="FinanceLab-${demo_tag}.apk"
demo_apk_asset="build/app/outputs/flutter-apk/$demo_apk_name"
cp "$demo_apk_source" "$demo_apk_asset"

sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
signer_path="$(find "$sdk_root/build-tools" -mindepth 2 -maxdepth 2 -type f -name apksigner | sort -V | tail -n 1)"
aapt_path="${signer_path%/apksigner}/aapt"
if [[ -z "$signer_path" || ! -x "$signer_path" || ! -x "$aapt_path" ]]; then
  echo "Instale Android SDK Build Tools com apksigner e aapt." >&2
  exit 1
fi
expected_signer="$(cat tool/demo_signing_sha256.txt)"
actual_signer="$("$signer_path" verify --print-certs "$demo_apk_asset" |
  sed -n 's/^Signer #1 certificate SHA-256 digest: //p' | head -n 1)"
if [[ "$actual_signer" != "$expected_signer" ]]; then
  echo "A assinatura mudou. Este APK não atualizará a demo já instalada." >&2
  exit 1
fi
apk_badging="$("$aapt_path" dump badging "$demo_apk_asset" | head -n 1)"
if [[ "$apk_badging" != *"versionCode='$demo_build_number'"* ||
      "$apk_badging" != *"versionName='$demo_version_name'"* ]]; then
  echo "A versão embutida no APK não corresponde a pubspec.yaml." >&2
  exit 1
fi

release_notes_path="$(mktemp)"
trap 'rm -f "$release_notes_path"' EXIT
demo_apk_sha="$(sha256sum "$demo_apk_asset" | cut -d' ' -f1)"
cat > "$release_notes_path" <<EOF
APK Android de demonstração do FinanceLab Mobile.

- Versão: $demo_version_name (build $demo_build_number)
- Commit: $(git rev-parse HEAD)
- SHA-256 do APK: $demo_apk_sha
- Botão **Explorar demonstração** ou login local **demo@financelab.local** / **demo123**.
- Dados fictícios locais. Este APK de depuração não é uma versão de produção.
EOF

if ! git rev-parse "$demo_tag^{commit}" >/dev/null 2>&1; then
  git tag -a "$demo_tag" -m "FinanceLab Mobile $demo_tag"
fi
if ! git ls-remote --exit-code --tags origin "refs/tags/$demo_tag" >/dev/null 2>&1; then
  git push origin "refs/tags/$demo_tag"
fi
gh release create "$demo_tag" "$demo_apk_asset" \
  --repo "$demo_repo" --verify-tag --prerelease --latest=false \
  --title "FinanceLab Mobile $demo_tag" --notes-file "$release_notes_path"
echo "Download: https://github.com/$demo_repo/releases/download/$demo_tag/$demo_apk_name"
