import os
import subprocess
import warnings
from sqlalchemy import exc as sa_exc

# Suppress the "Unrecognized server version info" warning for cleaner logs
warnings.filterwarnings('ignore', category=sa_exc.SAWarning)

from app import app
from waitress import serve


def _get_git_version():
    """Get the current git SHA for version tracking."""
    try:
        return subprocess.check_output(
            ['git', 'rev-parse', '--short', 'HEAD'],
            cwd=os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            stderr=subprocess.DEVNULL
        ).decode().strip()
    except Exception:
        return 'unknown'


if __name__ == '__main__':
    version = _get_git_version()
    env_name = os.environ.get('SGA_ENV', 'production').upper()
    host = '0.0.0.0'
    port = 5000

    print("=" * 60)
    print("🚀 SGA Web Server — PRODUCTION MODE (Waitress)")
    print("=" * 60)
    print(f"  Version:     {version}")
    print(f"  Environment: {env_name}")
    print(f"  Listening:   http://{host}:{port}")
    print(f"  Health:      http://{host}:{port}/health")
    print(f"  Threads:     6")
    print("=" * 60)
    print("  Presiona CTRL+C para detener el servidor.")
    print("=" * 60)

    # Run the production WSGI server
    # threads=6 allows handling multiple concurrent requests smoothly
    serve(app, host=host, port=port, threads=6)
