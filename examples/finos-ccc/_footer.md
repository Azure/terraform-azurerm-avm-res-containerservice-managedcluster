## Documentation maintenance

Edit `_header.md`, `_footer.md` and the Terraform sources, then regenerate this
README through PowerShell 7.4 or later with `Avm.Authoring`:

```powershell
Import-Module Avm.Authoring
avm docs
```

Before contribution, run `avm pre-commit`, review its changes, commit the intended
files and run `avm pr-check` on a clean worktree. These checks do not replace the
manual Azure deployment/idempotency assessment required for this BYO example.

Module telemetry is explicitly disabled by this example. For the module's
data-collection notice, see <https://aka.ms/avm/telemetryinfo>.
