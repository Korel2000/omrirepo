# Panther Bypass — repository files

This repository bundle contains the existing Debian package and basic APT metadata for hosting through GitHub Pages and adding to Sileo/Zebra.

## Package details

- **Package ID:** `com.guez.pantherbypass`
- **Display name:** Panther Bypass
- **Package version:** `1.0.0` (the version embedded in the uploaded `.deb`)
- **Architecture:** `iphoneos-arm64`
- **Dependency:** `mobilesubstrate (>= 0.9.5000)`
- **Debian filename:** `debs/com.guez.pantherbypass_1.0.0_iphoneos-arm64.deb`
- **SHA-256:** `43fe142467babbd1e470204fde2b8e226b6fc35349126c719d571edf1d582bfc`

**Compatibility note:** The package metadata describes its intended purpose as hiding Dopamine rootless jailbreak paths from Panther (`com.ylm.ylmPanther`). This bundle does not verify compatibility with Panther App 2.0.6 or modify the tweak binary. Test only on devices and apps you are authorized to test.

## Publish with GitHub Pages

1. Create a GitHub repository, for example `panther-bypass-repo`.
2. Upload the contents of this folder, keeping `Packages`, `Packages.gz`, `Release`, and `debs/` at the repository root.
3. In the repository, open **Settings → Pages** and publish from the `main` branch and `/ (root)`.
4. After Pages is enabled, the repository base address will be `https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/`.
5. Confirm that these files open in a browser:
   - `https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/Packages`
   - `https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/Packages.gz`
   - `https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/debs/com.guez.pantherbypass_1.0.0_iphoneos-arm64.deb`
6. Add the repository base address to Sileo or Zebra.

Replace `YOUR-USERNAME` and `YOUR-REPOSITORY` with your actual GitHub details. These metadata files are unsigned; repository signing is not configured in this starter bundle.

## Updating the repository after changing a package

Replace the `.deb`, then regenerate the index from the repository root:

```sh
dpkg-scanpackages -m debs /dev/null > Packages
gzip -n -9 -c Packages > Packages.gz
```

Keep the package's internal `Version` and the filename consistent. Do not claim Panther 2.0.6 compatibility unless it has been independently tested.
