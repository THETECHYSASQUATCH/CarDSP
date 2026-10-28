# Windows code signing for CarDSP

Code signing identifies the publisher and protects a binary from undetected modification. It does **not** guarantee SmartScreen reputation or that the application is safe.

## Certificate and tools

For public releases, obtain a trusted code-signing certificate from a certificate authority or use an eligible Microsoft Artifact Signing service. These are **not included** with Microsoft 365 E5. Prefer hardware-backed or managed signing keys. A self-signed certificate is useful for internal testing but is not trusted on other PCs by default.

Install the Windows SDK through Visual Studio Installer. It provides SignTool in the Windows Kits bin directory.

## Sign and verify

Use PowerShell 7. Adjust the executable path and certificate thumbprint. This example assumes the certificate and private key are accessible in the Current User Windows certificate store.

~~~powershell
$ErrorActionPreference = 'Stop'
$exe = 'C:\path\to\CarDSP.exe'
$thumbprint = 'REPLACE_WITH_REAL_CERT_THUMBPRINT'
$signTool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Filter signtool.exe -File -Recurse |
    Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } |
    Sort-Object FullName -Descending |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $signTool) { throw 'SignTool missing: install Windows SDK.' }
if (-not (Test-Path -LiteralPath $exe)) { throw "Executable missing: $exe" }
if ($thumbprint -eq 'REPLACE_WITH_REAL_CERT_THUMBPRINT') { throw 'Set certificate thumbprint.' }
& $signTool sign /sha1 $thumbprint /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $exe
if ($LASTEXITCODE -ne 0) { throw 'Signing failed.' }
& $signTool verify /pa /v $exe
if ($LASTEXITCODE -ne 0) { throw 'Verification failed.' }
Get-AuthenticodeSignature -FilePath $exe | Format-List Status,StatusMessage,SignerCertificate
~~~

If the certificate is in Local Machine instead, add the SignTool /sm option. For cloud signing or hardware tokens, follow the provider-specific SignTool instructions. The timestamp URL above is an example; use your provider's recommended RFC 3161 endpoint.

## Release process

1. Build the Release configuration and run tests.
2. Deploy matching Qt runtime libraries and plugins; test on a clean Windows installation.
3. Sign your distributable executables and any DLLs you own as appropriate.
4. Create the installer, then sign the installer separately. MSIX requires package-specific signing and identity settings.
5. Verify final signatures and timestamps. Any modification after signing invalidates the affected signature.
6. Publish only verified artifacts, along with checksums and release notes.

## GitHub Actions security

Use a protected release environment and protected tags. Prefer managed signing with short-lived identity over exportable PFX secrets. Never commit private keys, passwords or certificates with private keys. Do not expose signing credentials to untrusted pull requests or forks. Keep unsigned build/test jobs separate from signing jobs.

## References

- [SignTool](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool)
- [Authenticode](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/authenticode)
- [Artifact Signing](https://learn.microsoft.com/en-us/azure/trusted-signing/)
