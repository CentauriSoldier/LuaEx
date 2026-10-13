# Local browser APIs and runtimes

Everything needed by `Examples.html` is local. No npm install, Python, CDN,
system installation, environment changes, or external service is required.

| Folder | Version | Purpose | Licensing |
| --- | --- | --- | --- |
| `wasmoon/package` | 1.16.0 | Lua 5.4 WebAssembly VM and JavaScript bindings | MIT; preserve its `LICENSE` and the accompanying Lua notice |
| `node` | 22.20.0 Windows x64 | Optional static-server launcher, catalog generation and verification | Node MIT license plus bundled dependency notices in `node/LICENSE` |
| `workbench` | Repository source | Browser UI, worker, Lua loader, optional static server and developer checks | Repository license |

Wasmoon was downloaded from the official npm registry; its package SHA-512
integrity matched `sha512-FlRLb15WwAOz1A9OQDbf6oOKKSiefi5VK0ZRF2wgH9xk3o5SnU11tNPaOnQuAh1Ucr66cwwvVXaeVRaFdRBt5g==`.
Lua itself is MIT licensed: see `wasmoon/LUA-LICENSE.txt`.
The local JavaScript loader has an embedded-byte compatibility extension,
documented in `wasmoon/LOCAL-CHANGES.md`; the WASM binary is unchanged.

Node was extracted from the official `node-v22.20.0-win-x64.zip`; its SHA-256
was verified against `node/SHASUMS256.txt`. Only `node.exe`, its README, the
checksum list, and its full LICENSE notices are retained. npm was not installed.
The notices permit redistribution when retained with the files, including
uploading this folder to a Git repository. Node is optional and is not loaded by
the webpage. Its executable is about 85.6 MB; the browser runtime is under 0.5 MB.

Updating the browser bundle after editing, adding or moving examples (from the repository root):

```powershell
.\examples\api\node\node.exe .\examples\api\workbench\bundle.cjs
```

Checking actual examples and the AStar model in Wasmoon's WebAssembly runtime:

```powershell
.\examples\api\node\node.exe .\examples\api\workbench\verify.cjs
```

The verification report records example passes and failures; the verification
command exits unsuccessfully if any catalog example fails. The workbench displays
actual errors, and example updates do not change LuaEx's library implementation.

`bundle.js` contains the catalog, example/library source, resource bytes and
Wasmoon code/WebAssembly. It lets `Examples.html` run directly from disk without
requesting filesystem permissions or uploading/downloading files. Map save and
restore use page memory. Node is only an optional build/preview tool.
