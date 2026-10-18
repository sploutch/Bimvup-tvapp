# Compile l'APK sans Gradle : aapt2 -> javac -> d8 -> zipalign -> apksigner.
$ErrorActionPreference = "Stop"
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$bt = "$sdk\build-tools\36.0.0"
$androidJar = "$sdk\platforms\android-36\android.jar"
$env:JAVA_HOME = "$env:USERPROFILE\.jdks\jdk-21.0.12.1+1"
$jdk = "$env:JAVA_HOME\bin"
$app = Join-Path $PSScriptRoot "app"
$out = Join-Path $PSScriptRoot "build"
$keystore = Join-Path $PSScriptRoot "bimvup.keystore"
$apk = Join-Path $PSScriptRoot "Bimvup-TV.apk"

function Run($exe) {
    & $exe @args
    if ($LASTEXITCODE -ne 0) { throw "Echec : $exe $args" }
}

if (Test-Path $out) { Remove-Item -Recurse -Force $out }
New-Item -ItemType Directory -Force "$out\classes", "$out\dex" | Out-Null

Write-Host "1/6 Ressources"
Run "$bt\aapt2.exe" compile --dir "$app\res" -o "$out\res.zip"
Run "$bt\aapt2.exe" link -o "$out\unaligned.apk" -I $androidJar --manifest "$app\AndroidManifest.xml" `
    --min-sdk-version 21 --target-sdk-version 34 --version-code 1 --version-name 1.0 "$out\res.zip"

Write-Host "2/6 Java"
$sources = Get-ChildItem -Recurse "$app\src" -Filter *.java | ForEach-Object { $_.FullName }
Run "$jdk\javac.exe" -source 8 -target 8 -bootclasspath $androidJar -encoding UTF-8 -nowarn "-Xlint:-options" -d "$out\classes" @sources

Write-Host "3/6 Dex"
$classes = Get-ChildItem -Recurse "$out\classes" -Filter *.class | ForEach-Object { $_.FullName }
Run "$bt\d8.bat" --release --min-api 21 --lib $androidJar --output "$out\dex" @classes

Write-Host "4/6 Assemblage"
Run "$jdk\jar.exe" -u -0 -M -f "$out\unaligned.apk" -C "$out\dex" classes.dex
Run "$bt\zipalign.exe" -f -p 4 "$out\unaligned.apk" "$out\aligned.apk"

Write-Host "5/6 Signature"
if (-not (Test-Path $keystore)) {
    Run "$jdk\keytool.exe" -genkeypair -keystore $keystore -alias bimvup -keyalg RSA -keysize 2048 `
        -validity 36500 -storepass bimvup -keypass bimvup -dname "CN=Bimvup TV"
}
Run "$bt\apksigner.bat" sign --ks $keystore --ks-key-alias bimvup --ks-pass pass:bimvup `
    --key-pass pass:bimvup --out $apk "$out\aligned.apk"

Write-Host "6/6 Verification"
Run "$bt\apksigner.bat" verify $apk
Write-Host "APK pret : $apk"
