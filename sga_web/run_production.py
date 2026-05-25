import os
import subprocess
import warnings
from sqlalchemy import exc as sa_exc

# Suppress the "Unrecognized server version info" warning for cleaner logs
warnings.filterwarnings("ignore", category=sa_exc.SAWarning)

from app import app
from version import get_version, get_version_full, get_git_sha
from waitress import serve


if __name__ == "__main__":
    version = get_version()
    version_full = get_version_full()
    git_sha = get_git_sha()
    env_name = os.environ.get("SGA_ENV", "production").upper()
    host = "0.0.0.0"  # nosec B104
    port = 5000

    print("=" * 60)
    print("🚀 SGA Web Server — PRODUCTION MODE (Waitress)")
    print("=" * 60)
    print(f"  Version:     v{version} ({git_sha})")
    print(f"  Environment: {env_name}")
    print(f"  Listening:   http://{host}:{port}")
    print(f"  Health:      http://{host}:{port}/health")
    print("  Threads:     6")
    print("=" * 60)
    print("  Presiona CTRL+C para detener el servidor.")
    print("=" * 60)

    # Run the production WSGI server
    # threads=6 allows handling multiple concurrent requests smoothly
    serve(app, host=host, port=port, threads=6)

