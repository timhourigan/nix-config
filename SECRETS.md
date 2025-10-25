# Secrets

## Sops-Nix

- Used for true secrets, meaning that the cleartext does not exist in the
Nix Store (`/nix/store/`).

- Uses [sops-nix](https://github.com/Mic92/sops-nix) and [age encryption](https://github.com/FiloSottile/age).

### Sops-Nix Setup

#### Create Age Keys

```shell
# Create path for Age key
> mkdir -p ~/.config/sops/age

# Create a private key - Taking note of the public key displayed
> nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
age1...

# Optional - If the public key needs to be retrieved at a later point,
# use the following command
> nix shell nixpkgs#age -c age-keygen -y ~/.config/sops/age/keys.txt
age1...
```

#### Create SOPS Configuration

- Create a `.sops.yaml` file (at the root of the nix-config folder, alongside `flakes.nix`)
- Add the public key under keys (**Not** the private key)

<!--- editorconfig-checker-disable --->

```yaml
keys:
  - &primary age1...
creation_rules:
  - path_regex: secrets/secrets.yaml$
    key_groups:
      age:
        - *primary
```

<!--- editorconfig-checker-enable --->

> [!NOTE]
> This is a basic example. See `.sops.yaml` in this repository, for a more
> complete setup, with multiple public keys from users and hosts.

#### Create Secrets

```shell
# Create a secrets folder alongside `.sops.yaml`
> mkdir secrets

# Create/Modify the secrets file
> nix shell nixpkgs#sops -c sops secrets/secrets.yaml
# Add secrets to yaml in the default editor and save the file

# Optional - Update secrets if adding/removing keys to `.sops.yaml`
> nix shell nixpkgs#sops -c sops updatekeys secrets/secrets.yaml
```

#### Nix Configuration

See `flake.nix`, `modules/secrets/sops-nix.nix` and
`hosts/opx7070/configuration.nix`, as an example.

## Git-Crypt

- Used for obfuscation within this git repository. The cleartext will appear
in the Nix Store and so this should not be used for sensitive data.

### Git-Crypt Setup

- Initialise the repository:

```shell
# Initialise within the repository
# This will create a symmetric key at `.git/git-crypt/keys/default`
> git-crypt init
```

- Specify the files to be encrypted in `.gitattributes`.
- `.gitattributes` uses the same file pattern matching as `.gitignore`.

```shell
# In `.gitattributes` specify the file(s) to be encrypted
<file-pattern> filter=git-crypt diff=git-crypt
<file-pattern> filter=git-crypt diff=git-crypt
...
```

#### Transferring the key

```shell
> git-crypt export-key ../git-crypt-repo-key
```
