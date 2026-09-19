# nxapi / s3s authentication workaround

## Why the old Docker flow fails

The image `space4y/nxapi-s3s:0.7.0` uses an entrypoint that runs:

```bash
nxapi nso auth
```

and then parses a `session_token:` line from the command output.

The current nxapi authentication flow no longer exposes the session token in that output. It stores the Nintendo Account session token in nxapi's persistent storage instead.

As a result, the old image can stop with:

```text
Error: Remote configuration prevents Coral authentication
```

This does **not** necessarily mean the Nintendo Account login itself is broken.

## Working method

Use the current nxapi image for Nintendo Account / SplatNet authentication, while keeping the old image only for the s3s Python program.

### 1. Authenticate with current nxapi

```powershell
docker run --rm -it `
  -v "C:\Users\AMD\Desktop\s3s:/data" `
  ghcr.io/samuelthomas2774/nxapi:ref-main `
  nso auth
```

A successful authentication looks like:

```text
Authenticated as Nintendo Account ...
Set as default user
```

### 2. Verify the saved authentication

```powershell
docker run --rm -it `
  -v "C:\Users\AMD\Desktop\s3s:/data" `
  ghcr.io/samuelthomas2774/nxapi:ref-main `
  nso user
```

If the command prints Nintendo Account / Nintendo Switch user information, the saved authentication is usable.

> Do not use `nso token` as a command to display the existing token. In the current nxapi CLI, `nso token` is a command for setting a token interactively or from its positional argument.

### 3. Generate the s3s config

```powershell
docker run --rm -it `
  -v "C:\Users\AMD\Desktop\s3s:/data" `
  ghcr.io/samuelthomas2774/nxapi:ref-main `
  util update-s3s-token /data/config.txt
```

A successful run includes:

```text
Authenticating to SplatNet 3
writing s3s config file
```

The resulting `config.txt` contains authentication material. **Never commit it to GitHub.**

### 4. Run the old s3s Python program without its broken entrypoint

The old image expects its configuration at `/s3s/config.txt`, while the current nxapi command writes it to the mounted `/data/config.txt`.

Copy the generated configuration into the old image and run `s3s.py` directly:

```powershell
docker run --rm -it `
  -v "C:\Users\AMD\Desktop\s3s:/data" `
  --entrypoint /bin/sh `
  space4y/nxapi-s3s:0.7.0 `
  -c "cp /data/config.txt /s3s/config.txt && cd /s3s && python s3s.py --getseed && mv gear_*.json /data/"
```

This bypasses the obsolete authentication code in the old image.

Generated `gear_*.json` files are then placed in:

```text
C:\Users\AMD\Desktop\s3s
```

## Important security notes

Do not publish:

- `config.txt`
- Nintendo Account session tokens
- JWTs
- SplatNet `gtoken`
- `bulletToken`
- private authentication logs

A public repository should contain commands and troubleshooting information only.

## Short version

```text
OLD image:
space4y/nxapi-s3s:0.7.0
    └── old nxapi auth parser ❌

CURRENT nxapi:
ghcr.io/samuelthomas2774/nxapi:ref-main
    ├── nso auth                 ✅
    ├── nso user                 ✅
    └── util update-s3s-token    ✅
                 │
                 ▼
            config.txt
                 │
                 ▼
OLD image, Python only:
s3s.py --getseed                ✅
```

The key lesson is: **do not keep trying to repair the old image's Nintendo authentication step when current nxapi can perform the authentication and generate the s3s configuration separately.**
