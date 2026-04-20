# nanvix/toolchain-rust

Custom Rust fork (`nanvix-x86` toolchain) with Nanvix OS target support for `i686-unknown-nanvix`.

## Overview

This repository builds and publishes a Docker image containing the custom Rust toolchain for Nanvix. The toolchain is installed under `/opt/nanvix/toolchain-rust/` and includes:

- `rustc` — Rust compiler with `i686-unknown-nanvix` target support
- `cargo` — package manager (from stage2-tools-bin)
- Rust library source (`lib/rustlib/src/rust/library/`) for `-Zbuild-std` support
- Pre-linked as `nanvix-x86` via `rustup toolchain link`

## Dependencies

This toolchain depends on `nanvix/toolchain-gcc` for the newlib sysroot (headers and libraries needed by `std` build). The Dockerfile uses a multi-stage build to pull the GCC sysroot at build time.

## Usage

```bash
# Pull the image.
docker pull ghcr.io/nanvix/toolchain-rust:1.0.0

# Verify the toolchain.
docker run --rm ghcr.io/nanvix/toolchain-rust:1.0.0 rustc --version
docker run --rm ghcr.io/nanvix/toolchain-rust:1.0.0 rustup +nanvix-x86 show
```

## Building Locally

```bash
docker build -t ghcr.io/nanvix/toolchain-rust:local .
```

## Versioning

Independent semantic versioning starting at `1.0.0`. Version bumps here do **not** require a version bump in the main `nanvix/nanvix` repository.

## Pinned Upstream Commits

| Component | Repository | Commit |
|-----------|-----------|--------|
| Rust | [nanvix/rust](https://github.com/nanvix/rust) | `f258dd9` |

## Notes

- The WASI SDK is downloaded during the Docker build (already a tarball, not a Nanvix fork)
- Requires a compatible `toolchain-gcc` version for the newlib sysroot

## License

MIT — see [LICENSE.txt](LICENSE.txt).
