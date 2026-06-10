# Xerotier.ai Binaries

<div style="text-align: center;">
<img src="https://xerotier.ai/xerotier-ogimage.png" alt="Project Logo" width="50%">
</div>

A high-performance, accelerated intelligence platform.

This repository serves prebuilt Xerotier binaries through GitHub Releases.
Every release ships the `xeroctl` CLI, the XIM inference agent, the XEM
execution agent, and the desktop app, built for Linux and macOS (Darwin).

Assets are named `<binary>-<OS>-<ARCH>`, where the suffix matches `uname -s`
and `uname -m` on the target host, for example `xeroctl-Linux-x86_64` or
`xeroctl-Darwin-arm64`. A host can always fetch its own build with a single
command.

## Getting Started

Download a binary from the
[latest release](https://github.com/Xerotier/binaries/releases/latest), mark
it executable, and put it on your PATH:

``` shell
curl -fLO "https://github.com/Xerotier/binaries/releases/latest/download/xeroctl-$(uname -s)-$(uname -m)"
chmod +x "xeroctl-$(uname -s)-$(uname -m)"
sudo install "xeroctl-$(uname -s)-$(uname -m)" /usr/local/bin/xeroctl
```

The same pattern works for every asset: `xeroctl`, `xerotier-xim-agent`,
`xerotier-xem-agent`, and `xerotier-desktop`.

Before running an agent, set the `XEROTIER_AGENT_JOIN_KEY` environment
variable with your join key. This key is required for the agent to connect to
the Xerotier network. You can obtain a join key from the Xerotier dashboard.

Documentation for running private agents can be found in the
[docs](https://xerotier.ai/docs/private-agents), which provides detailed
information on enrollment, configuration, and day-to-day operation.

### xeroctl (CLI)

`xeroctl` is the command-line client for the Xerotier API:

``` shell
xeroctl config init
xeroctl status
```

* The first command interactively stores your deployment base URL and API key
  in `~/.config/xeroctl/config.toml`.
* The second command verifies the connection against your deployment.

### XIM inference agent

> **vLLM required:** the XIM agent drives a local vLLM installation. Make
> sure `vllm` is on the PATH (or pass `--vllm-path`) before starting the
> agent. To run a fully packaged agent in a container instead, use the
> [container-agents](https://github.com/Xerotier/container-agents) images.

``` shell
export XEROTIER_AGENT_JOIN_KEY=xxxxxxxx
xerotier-xim-agent enroll
xerotier-xim-agent run
```

* The first command sets the required environment variable for the join key.
* The second command enrolls this host with the router and persists the
  enrollment state.
* The third command starts the agent from the persisted enrollment state.

### XEM execution agent

The recommended path is `xeroctl bootstrap`, which creates the service
account and directories, renders the agent config, installs a systemd unit,
enrolls the agent, and waits for readiness:

``` shell
sudo xeroctl bootstrap --join-key xxxxxxxx
```

To run the binary directly instead:

``` shell
xerotier-xem-agent --enroll-url https://your-router.example.com --join-key xxxxxxxx
```

### Desktop app

The desktop app runs the XIM agent in-process and is a full client for the
Xerotier API:

``` shell
curl -fLO "https://github.com/Xerotier/binaries/releases/latest/download/xerotier-desktop-$(uname -s)-$(uname -m)"
chmod +x "xerotier-desktop-$(uname -s)-$(uname -m)"
./xerotier-desktop-$(uname -s)-$(uname -m)
```

On first launch, open **Setup**, paste your join key, and click
**Install & Start**.

> **macOS:** prefer the notarized `Xerotier-<version>.dmg` when available;
> see the [macOS install docs](https://xerotier.ai/docs/xim/macos). A bare
> binary downloaded with a browser carries the quarantine attribute, which
> you can clear with `xattr -d com.apple.quarantine <file>`.

### Optional system configuration

While optional, these settings can help improve performance when running AI
workloads on bare hosts. They adjust the maximum buffer sizes for network
communication, which can be beneficial for certain workloads that require
high throughput.

``` shell
sudo sysctl -w net.core.wmem_max=4194304 | tee -a /etc/sysctl.conf
sudo sysctl -w net.core.rmem_max=4194304 | tee -a /etc/sysctl.conf
```
