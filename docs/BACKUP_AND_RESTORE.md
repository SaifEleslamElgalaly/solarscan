# Source and private recovery assets

This public repository includes application source, Flutter platform project files,
dependency lockfiles, generated platform icons and the SolarScan logo. The
preservation update does not change application logic.

## Private assets

Personal/profile images, remaining UI images, uploaded scans, database rows,
local settings, full thesis/presentation material, training datasets and historical
model weights are retained in the owner's private encrypted backup. They are not
published here. For an exact reproduction, restore the missing `mobile/assets`
and `backend_php/assets` files from that backup before building/running.

The deployed classifier is available at the Hugging Face link in the main README.
The private backup additionally preserves ResNet/Faster R-CNN weights and full
training runs. Use the fresh consistent MySQL export in the private backup for
the captured current database; `db/schema.sql` here contains structure only.

## Environment

Use a Flutter SDK compatible with Dart ^3.11.1, run `flutter pub get`, and configure
the API host. Local SDK paths, signing keys and generated build caches are excluded.
The preserved widget test is the original Flutter counter template, not a validated
SolarScan regression test. No complete application build was run by this backup pass.

For private archive recovery, download every numbered RAR part into one directory,
open the first part with WinRAR or a compatible RAR5 reader, and supply the separate
recovery password. Extract the ZIP inside. Its `BACKUP-MANIFEST.json` includes file
paths and SHA-256 values. Restore into a new directory and test the database in an
isolated instance before replacing any live installation.
