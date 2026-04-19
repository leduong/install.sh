# Node Exporter — Ubuntu installation guide

## Requirements

- Ubuntu 18.04 or newer (or compatible Debian-based distro)
- A user with sudo privileges
- Bash shell available (default on Ubuntu)
- Basic network access (if the script downloads packages)

## Quick start (local file)

1. Open a terminal in the directory that contains `install.sh`.
2. Make the script executable and run it with sudo:

```bash
chmod +x ./install.sh
sudo ./install.sh
```

If you prefer to run without changing permissions:

```bash
sudo bash ./install.sh
```

## Quick start (download from remote)

If you need to fetch the script first:

```bash
sudo apt update && apt install -y curl wget ca-certificates
curl -fsSL https://github.com/leduong/install.sh/raw/refs/heads/node-exporter/install.sh | sudo -E bash -
```

## Recommended pre-steps

- Update package lists:

```bash
sudo apt update
```

- Install common utilities if missing:

```bash
sudo apt install -y curl wget ca-certificates
```

## Troubleshooting

- Permission denied: ensure the file is executable (`chmod +x`) and use `sudo` if root access is required.
- Network/download failures: verify network connectivity and the correctness of any URLs used by the script.
- Missing package error: run `sudo apt update` then re-run the installer.

Enable verbose logging (if script supports it) to capture errors:

```bash
sudo ./install.sh --verbose 2>&1 | tee install.log
```

## Security notes

- Inspect the script before running it: `less install.sh` or `sed -n '1,200p' install.sh`.
- Only run scripts from trusted sources.

## Contacts & contribution

- For issues, open an issue in the repository or contact the maintainer.
- Contributions: fork the repo, edit `install.sh` or docs, and submit a pull request.

## License

Follow the repository's license. If none, assume standard open-source licensing applies and consult the project owner.

That's it — run the script following the Quick start section and consult the script's built-in help for script-specific options.

---

## 💖 Support Future Development

If you find these scripts useful, consider supporting the project:

| 💰 Currency                 | 📋 Address                                    |
| --------------------------- | --------------------------------------------- |
| ₿ **BTC** (Bitcoin)         | `bc1qr0s6dv4rvh245wax2kwdwyv8rz8radlfnquc7k`  |
| ⟠ **ETH** (Ethereum)        | `0x58d8b821dE46D61d9d1034313919d5370F4A8E88`  |
| ◎ **SOL** (Solana)          | `gG1VLq8GFXMqPu2mNXkHHk1535MHg66pQVh8QYz5krj` |
| 💵 **USDT** (Tether on ETH) | `0x58d8b821dE46D61d9d1034313919d5370F4A8E88`  |

---

<p align="center">
  ⭐ Star this repo if you find it helpful!<br/>
  Made with ❤️ by <a href="https://github.com/leduong">leduong</a>
</p>
