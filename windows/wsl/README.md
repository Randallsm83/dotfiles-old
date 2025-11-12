# WSL Configuration

This directory contains WSL2 (Windows Subsystem for Linux) configuration files.

## Files

### `.wslconfig`

This file configures global settings for WSL2. It must be located in your Windows user profile directory (`%USERPROFILE%\.wslconfig`).

**Current Settings:**
```ini
[wsl2]
processors=8
```

#### Available Settings

**[wsl2] Section:**

- **processors** - Number of logical processors to assign to the WSL2 VM
  - Default: All available processors
  - Current: `8` processors

- **memory** - Amount of memory to assign to the WSL2 VM
  - Example: `memory=8GB`
  - Default: 50% of total memory on Windows, up to 8GB

- **swap** - Amount of swap space
  - Example: `swap=8GB`
  - Default: 25% of memory size

- **swapFile** - Path to swap file
  - Example: `swapFile=C:\\temp\\wsl-swap.vhdx`

- **localhostForwarding** - Enable/disable localhost forwarding
  - Example: `localhostForwarding=true`
  - Default: `true`

- **kernel** - Custom Linux kernel path
  - Example: `kernel=C:\\temp\\myCustomKernel`

- **kernelCommandLine** - Additional kernel command line parameters
  - Example: `kernelCommandLine=vsyscall=emulate`

- **pageReporting** - Enable page reporting for memory reclamation
  - Example: `pageReporting=true`
  - Default: `true`

- **guiApplications** - Enable WSLg (GUI applications)
  - Example: `guiApplications=true`
  - Default: `true`

- **nestedVirtualization** - Enable nested virtualization
  - Example: `nestedVirtualization=true`
  - Default: `true`

- **vmIdleTimeout** - Time in milliseconds VM will idle before shutting down
  - Example: `vmIdleTimeout=60000`
  - Default: `60000` (60 seconds)

## Bootstrap Integration

The Windows bootstrap script automatically creates a symlink from this file to `%USERPROFILE%\.wslconfig`.

```powershell
# Full setup (includes WSL config)
.\windows\bootstrap.ps1

# Link only
.\windows\bootstrap.ps1 -LinkOnly
```

## Applying Changes

After modifying `.wslconfig`, you must **restart WSL**:

```powershell
# Shutdown WSL completely
wsl --shutdown

# Start your default distribution
wsl
```

Changes take effect immediately after WSL restarts.

## Performance Tuning

### For Development Workloads

```ini
[wsl2]
processors=8
memory=16GB
swap=8GB
localhostForwarding=true
```

### For Memory-Constrained Systems

```ini
[wsl2]
processors=4
memory=4GB
swap=2GB
pageReporting=true
```

### For Docker/Containers

```ini
[wsl2]
processors=8
memory=8GB
swap=4GB
nestedVirtualization=true
```

## Troubleshooting

### WSL not using configured settings
- Verify file location: `$env:USERPROFILE\.wslconfig`
- Check file format: Must use Windows line endings (CRLF)
- Restart WSL: `wsl --shutdown`
- Check WSL version: `wsl --version` (requires WSL 2)

### Out of memory errors
- Increase `memory` setting
- Add or increase `swap` setting
- Enable `pageReporting=true`

### Performance issues
- Reduce `processors` if CPU is bottleneck
- Increase `memory` if swapping is occurring
- Check `vmIdleTimeout` for idle behavior

### Symlink not created
- Run bootstrap with `-Force` flag
- Check Developer Mode is enabled or run as administrator
- Verify source file exists in dotfiles

## See Also

- [Microsoft WSL Configuration Docs](https://docs.microsoft.com/en-us/windows/wsl/wsl-config)
- [WSL Best Practices](https://docs.microsoft.com/en-us/windows/wsl/setup/environment)
- [Main dotfiles README](../../README.md)
- [Windows Bootstrap Script](../bootstrap.ps1)
