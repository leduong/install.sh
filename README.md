# O11 Streamer V4

Tested on **Ubuntu 20.04-25.04 Linux/AMD64**

```
sudo apt update && apt upgrade -y
sudo apt install -y curl wget
curl -fsSL https://github.com/leduong/install.sh/raw/refs/heads/o11/install.sh | sudo -E bash -
```

## Web UI

```
http://YOUR_IP:8283
Username: admin
Password: 1
```

# FIX PERMISSION ISSUES if any

```sh
chown -R o11:o11 /home/o11
chown -R o11:o11 /mnt/hls
chown -R o11:o11 /mnt/dl
rm /home/o11/o11.log
```

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
