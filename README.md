# Erebine.ai Binaries

<div style="text-align: center;">
<img src="https://erebine.ai/erebine-ogimage.png" alt="Project Logo" width="50%">
</div>

A high-performance, accelerated intelligence platform.

This repository serves prebuilt Erebine binaries through GitHub Releases.
Every release ships the `erectl` CLI, the eim inference agent, and the eem
execution agent for Linux and macOS (Darwin), plus the desktop app for macOS.

Assets are named `<binary>-<OS>-<ARCH>`, where the suffix matches `uname -s`
and `uname -m` on the target host, for example `erectl-Linux-x86_64` or
`erectl-Darwin-arm64`. A host can always fetch its own build with a single
command.

## Getting Started

Download a binary from the
[latest release](https://github.com/Erebine/binaries/releases/latest), mark
it executable, and put it on your PATH:

``` shell
curl -fLO "https://github.com/Erebine/binaries/releases/latest/download/erectl-$(uname -s)-$(uname -m)"
chmod +x "erectl-$(uname -s)-$(uname -m)"
sudo install "erectl-$(uname -s)-$(uname -m)" /usr/local/bin/erectl
```

The same pattern works for every asset: `erectl`, `erebine-eim-agent`,
`erebine-eem-agent`, and `erebine-desktop`.

Before running an agent, set the `EREBINE_AGENT_JOIN_KEY` environment
variable with your join key. This key is required for the agent to connect to
the Erebine network. You can obtain a join key from the Erebine dashboard.

Documentation for running private agents can be found in the
[docs](https://erebine.ai/docs/private-agents), which provides detailed
information on enrollment, configuration, and day-to-day operation.

### erectl (CLI)

`erectl` is the command-line client for the Erebine API.

Install dependencies:

``` shell
# Debian/Ubuntu
sudo apt install -y libzstd1 libcurl4 ca-certificates
# RHEL/Rocky
sudo dnf install -y libzstd libcurl ca-certificates
# macOS (Homebrew)
brew install zstd
```

Then point it at your deployment:

``` shell
erectl config init
erectl status
```

* The first command interactively stores your deployment base URL and API key
  in `~/.config/erectl/config.toml`.
* The second command verifies the connection against your deployment.

### eim inference agent

> **vLLM required:** the eim agent drives a local vLLM installation. Make
> sure `vllm` is on the PATH (or pass `--vllm-path`) before starting the
> agent. To run a fully packaged agent in a container instead, use the
> [container-agents](https://github.com/Erebine/container-agents) images.

Install dependencies:

``` shell
# Debian/Ubuntu
sudo apt install -y libzmq5 libsodium23 libzstd1
# RHEL/Rocky (zeromq and libsodium ship in EPEL)
sudo dnf install -y epel-release
sudo dnf install -y zeromq libsodium libzstd
# macOS (Homebrew)
brew install zeromq zstd
```

Enroll and run:

``` shell
export EREBINE_AGENT_JOIN_KEY=xxxxxxxx
erebine-eim-agent enroll
erebine-eim-agent run
```

* The first command sets the required environment variable for the join key.
* The second command enrolls this host with the router and persists the
  enrollment state.
* The third command starts the agent from the persisted enrollment state.

### eem execution agent

Install dependencies:

``` shell
# Debian/Ubuntu
sudo apt install -y libzmq5 libsodium23 libzstd1 libcurl4 ca-certificates
# RHEL/Rocky (zeromq and libsodium ship in EPEL)
sudo dnf install -y epel-release
sudo dnf install -y zeromq libsodium libzstd libcurl ca-certificates
# macOS (Homebrew)
brew install zeromq zstd
```

The recommended path is `erectl bootstrap`, which creates the service
account and directories, renders the agent config, installs a systemd unit,
enrolls the agent, and waits for readiness:

``` shell
sudo erectl bootstrap --join-key xxxxxxxx
```

To run the binary directly instead:

``` shell
erebine-eem-agent --enroll-url https://your-router.example.com --join-key xxxxxxxx
```

### Desktop app (macOS)

The desktop app is macOS-only: it runs the eim agent in-process and is a
full client for the Erebine API. The bare binary loads its runtime
libraries from Homebrew:

``` shell
brew install zeromq zstd
```

Download and launch:

``` shell
curl -fLO "https://github.com/Erebine/binaries/releases/latest/download/erebine-desktop-Darwin-$(uname -m)"
chmod +x "erebine-desktop-Darwin-$(uname -m)"
xattr -d com.apple.quarantine "erebine-desktop-Darwin-$(uname -m)" 2>/dev/null || true
./"erebine-desktop-Darwin-$(uname -m)"
```

On first launch, open **Setup**, paste your join key, and click
**Install & Start**.

> **Tip:** prefer the notarized `Erebine-<version>.dmg` when available; see
> the [macOS install docs](https://erebine.ai/docs/eim/macos). The DMG app
> bundles its runtime libraries, so Homebrew is not required.

### Optional system configuration

While optional, these settings can help improve performance when running AI
workloads on bare hosts. They adjust the maximum buffer sizes for network
communication, which can be beneficial for certain workloads that require
high throughput.

``` shell
sudo sysctl -w net.core.wmem_max=4194304 | tee -a /etc/sysctl.conf
sudo sysctl -w net.core.rmem_max=4194304 | tee -a /etc/sysctl.conf
```
