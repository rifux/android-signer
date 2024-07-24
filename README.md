android-signer by rifux
===========

> sign your builds with ease

<img src="https://github.com/rifux/android-signer/blob/release/screen.png">

Getting started
---------------

## 1. Fetch the script itself

```bash
wget https://raw.githubusercontent.com/rifux/android-signer/release/sign.sh
```

## 2. Run sign.sh and follow the prompts

```bash
./sign.sh
```

## 3. Inherit keys into your device tree

Add these lines in `kona.mk` placed at device/{vendor_name}/{device_codename}/kona.mk (_change {vendor_name} to your device vendor, for example Xiaomi; same for {device_codename}_)

```kona.mk
# Signing
include vendor/lineage-priv/keys/keys.mk
```

## 4. Try building

Follow your custom ROM build guide (lunch device; mka bacon ...)