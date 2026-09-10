# AGENTS.md

Guidelines for AI agents working in this repository.

## Repository layout

This is a personal Nix flake exposing a small collection of packages.

- `flake.nix` — the flake; every package is exposed via `perSystem.packages`.
- `pkgs/<first-letter>/<package-name>/default.nix` — one directory per package,
  grouped by the first letter of the package name (e.g. `pkgs/c/coderabbit-cli/`).
- `README.md` — package list and snippets for generating release asset hashes.

## Adding a new package

1. Create the package directory `pkgs/<first-letter>/<package-name>/` and write
   its `default.nix` there. Follow the style of the existing packages: a function
   taking `{ lib, stdenv, fetchurl, ... }`, a `sources` attribute set keyed by
   system for prebuilt binaries, and a `meta` block with `description`,
   `homepage`, `license`, `mainProgram`, `platforms` and — for binary
   distributions — `sourceProvenance = [ lib.sourceTypes.binaryNativeCode ]`.
2. **Register the package in `flake.nix`.** Add a line to the `packages`
   attribute set inside `perSystem`, keeping the entries in alphabetical order:

   ```nix
   packages = with pkgs; {
     # ...
     coderabbit-cli = callPackage ./pkgs/c/coderabbit-cli { };
     # ...
   };
   ```

   A package that only exists under `pkgs/` but is not listed in `flake.nix` is
   not built and not reachable via `nix build`/`nix run`, so this step is
   mandatory for every new package.
3. Add the package name to the `packages` list in `README.md`.
4. Verify the package evaluates and builds:

   ```shell
   nix flake check
   nix build .#<package-name>
   ```

## Conventions

- Keep the `packages` attribute set in `flake.nix` sorted alphabetically.
- Use the hash-generation snippets in `README.md` to compute `sha256-` hashes
  for release assets; always include the `sha256-` prefix.
- Prefer `fetchurl` + `autoPatchelfHook` for prebuilt Linux binaries, and list
  the required runtime libraries in `buildInputs`.
- **Exception — single-file executables with an appended payload** (Bun
  `--compile`, Deno `compile`, PyInstaller, and similar): these locate their
  embedded payload by absolute byte offset, so `autoPatchelfHook` — and
  `fixupPhase`'s strip/RPATH-shrink — corrupt them by shifting those offsets.
  The build still succeeds and the binary still runs, but it silently loses its
  embedded entrypoint, which makes this easy to miss (see
  `pkgs/c/coderabbit-cli`, where it left a `coderabbit` that behaved as a bare
  Bun runtime). For these, set `dontFixup = true`, install the binary
  unmodified, and wrap it with `makeWrapper ${stdenv.cc.bintools.dynamicLinker}`
  passing the real binary via `--add-flags` plus any `LD_LIBRARY_PATH` it needs.
  A quick check after packaging: run the binary's `--version`/`--help` and
  confirm the output is the tool's own, not the embedded runtime's.
- Supported systems are `x86_64-linux`, `x86_64-darwin`, `aarch64-linux` and
  `aarch64-darwin`; restrict `meta.platforms` to the systems a package actually
  ships assets for.
