# Local Multiplayer Pixel Prototype

A small GitHub-ready TypeScript game prototype using Phaser 3, Node.js, Express, Socket.IO, and Vite.

The first version is intentionally simple: one person hosts a local server, friends on the same Wi-Fi/network join from a browser, and everyone appears in one shared room. Players move with WASD and movement syncs in real time.

## Requirements

- Node.js
- npm
- Git

## Install

```bash
npm install
```

## Run Locally

```bash
npm run dev
```

This starts:

- Express and Socket.IO on `http://localhost:3000`
- Vite client on `http://localhost:5173`

Open `http://localhost:5173` on the host computer.

## Build

```bash
npm run build
```

## Start Built Local Server

```bash
npm run start
```

After running `npm run build`, this serves the built game from `http://localhost:3000`.

## How the Host Finds Their Local IP Address

On Windows PowerShell:

```powershell
ipconfig
```

Look for the `IPv4 Address` under the active Wi-Fi or Ethernet adapter. It often looks like `192.168.1.25`.

On macOS or Linux:

```bash
ifconfig
```

or:

```bash
ip addr
```

## How Friends Join

Everyone must be on the same local network as the host.

During development, friends can open:

```text
http://HOST_LOCAL_IP:5173
```

Example:

```text
http://192.168.1.25:5173
```

The development server proxies multiplayer traffic through the same address, so friends should only need the `5173` URL while you are running `npm run dev`.

After a production build with `npm run build` and `npm run start`, friends can open:

```text
http://HOST_LOCAL_IP:3000
```

## Troubleshooting

- Everyone must be on the same Wi-Fi/network.
- Windows Firewall may ask whether to allow Node.js. Allow access for private networks.
- If a port is already in use, stop the other app or change the port in the scripts/server config.
- If friends can load the page but do not see movement, restart `npm run dev` and confirm the backend says `Server listening on http://localhost:3000`.

## Basic GitHub Workflow

Initial setup:

```bash
git init
git add .
git commit -m "Initial multiplayer prototype scaffold"
git branch -M main
git remote add origin YOUR_GITHUB_REPO_URL
git push -u origin main
```

Normal change workflow:

```bash
git checkout -b feature/my-change
git add .
git commit -m "Describe my change"
git push -u origin feature/my-change
```

Then open a pull request on GitHub.
