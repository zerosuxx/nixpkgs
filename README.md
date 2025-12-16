# nixpkgs

### packages
- `adminer`
- `elasticsearch`
- `kibana`
- `terraform`

### generate hashes
```shell
repo=zerosuxx/db-adminer
name="adminer"
version="4.8.4-evo.1"
for system in "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"; do
        echo "$system" = \"sha256-$(curl -fsSL "https://github.com/$repo/releases/download/$version/$name-$system" | openssl dgst -sha256 -binary | openssl base64 -)\"\;
done
```

```shell
repo=iximiuz/labctl
name="labctl"
version="v0.1.54"

for system in "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"; do
  case "$system" in
    x86_64-linux)   asset="linux_amd64" ;;
    x86_64-darwin)  asset="darwin_amd64" ;;
    aarch64-linux)  asset="linux_arm64" ;;
    aarch64-darwin) asset="darwin_arm64" ;;
    *) echo "Unsupported system: $system" >&2; exit 1 ;;
  esac

  printf "%-14s = %s\n" "$system" "sha256-$( \
    curl -fsSL "https://github.com/$repo/releases/download/${version}/${name}_${asset}.tar.gz" \
    | openssl dgst -sha256 -binary \
    | openssl base64 - \
  )\";"
done
```
