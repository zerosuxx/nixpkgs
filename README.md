# nixpkgs

### generate hashes
```shell
version="4.8.4-evo.1"
for system in "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"; do
        echo "$system" = \"sha256-$(curl -fsSL "https://github.com/zerosuxx/db-adminer/releases/download/$version/adminer-$system" | openssl dgst -sha256 -binary | openssl base64 -)\"\;
done
```