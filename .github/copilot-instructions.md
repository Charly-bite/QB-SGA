# SGA Development Assistant Rules

- Never start/restart dev server unless user explicitly asks
- SGA_dev is isolated from SGAv1.01 — never modify pre-prod files directly
- Wrap all SAP/SQL calls in try/except with logging
- Use os.path.join for all file paths
- CSV codes (H-codes, P-codes) must be enforced as str type
- Use SharedFileManager for concurrent file access
- Legacy Tkinter GUI is deprecated — web only

## DevOps Context
- test_before_deploy: Always run pytest before deploying
- health_check: Verify /health endpoint after any deployment
- security_scan: Run scripts/security_scan.ps1 before pushing sensitive changes
- branch_flow: feature/* -> development -> main
