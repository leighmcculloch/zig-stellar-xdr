# zig-stellar-xdr

Zig types for Stellar XDR, generated from the XDR definitions.

> [!CAUTION]
> This is experimental and should not be used for anything other than toy experiments.

## Usage

Add as a dependency in your `build.zig.zon`:

```
zig fetch --save git+https://github.com/AStarStartup/zig-stellar-xdr
```

Then in your `build.zig`:

```zig
const stellar_xdr = b.dependency("stellar_xdr", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("stellar-xdr", stellar_xdr.module("stellar-xdr"));
```

## Build

```
make
```

## Test

```
zig build test
```
