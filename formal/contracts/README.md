# Formal Contracts

These files describe the intended boundary-level proof scope for the modular
fullstream scaffolding.

Current priority:

- `timing-subsystem`
- `frontend-boundary`
- `stream-pipeline`
- `spy-buffer-boundary`
- `hermes-boundary`
- `daphne-fullstream-boundary-top`

The imported fullstream RTL remains active and unchanged. The contracts here
apply to the additive wrappers in `ip_repo/daphne3_ip/rtl/isolated/`.
