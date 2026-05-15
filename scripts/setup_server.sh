#!/bin/bash
# Server Setup Script for SGA Shared Deployment
# Run this on the file server to setup Samba share

set -e

echo "=================================================="
echo "SGA File Server Setup - Samba Configuration"
echo "=================================================="
echo ""

# Configuration
SHARE_NAME="sga_shared"
SHARE_PATH="/srv/sga_shared"
SGA_USER="sga"
SGA_GROUP="sga"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (sudo)"
    exit 1
fi

echo "[1/6] Installing Samba..."
apt update
apt install -y samba samba-common-bin

echo ""
echo "[2/6] Creating shared directory..."
mkdir -p "$SHARE_PATH"/{master_data,assets,operational,config,logs,generated_labels}
mkdir -p "$SHARE_PATH/master_data"/{unified_db,original_data}
mkdir -p "$SHARE_PATH/assets/pictograms"

echo ""
echo "[3/6] Creating SGA user and group..."
if ! getent group "$SGA_GROUP" > /dev/null 2>&1; then
    groupadd "$SGA_GROUP"
    echo "Created group: $SGA_GROUP"
fi

if ! id "$SGA_USER" > /dev/null 2>&1; then
    useradd -r -g "$SGA_GROUP" -s /bin/false "$SGA_USER"
    echo "Created user: $SGA_USER"
fi

echo ""
echo "[4/6] Setting permissions..."
chown -R "$SGA_USER:$SGA_GROUP" "$SHARE_PATH"
chmod -R 775 "$SHARE_PATH"
chmod -R g+s "$SHARE_PATH"  # Set GID bit for new files

echo ""
echo "[5/6] Configuring Samba..."

# Backup existing config
if [ -f /etc/samba/smb.conf ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup.$(date +%Y%m%d_%H%M%S)
fi

# Add share configuration
cat >> /etc/samba/smb.conf << EOF

# ============================================
# SGA Shared Folder
# ============================================
[$SHARE_NAME]
    comment = SGA Sistema de Gestion de Almacen
    path = $SHARE_PATH
    browseable = yes
    writable = yes
    valid users = @$SGA_GROUP
    create mask = 0664
    directory mask = 0775
    force group = $SGA_GROUP
    
    # File locking for concurrency
    strict locking = yes
    oplocks = no
    level2 oplocks = no
    
    # Performance
    vfs objects = acl_xattr
    
    # Logging
    log file = /var/log/samba/sga_%m.log
    max log size = 50

EOF

echo ""
echo "[6/6] Creating Samba password for SGA user..."
echo "Please enter password for Samba user '$SGA_USER':"
smbpasswd -a "$SGA_USER"

echo ""
echo "Enabling Samba user..."
smbpasswd -e "$SGA_USER"

echo ""
echo "Restarting Samba services..."
systemctl restart smbd
systemctl enable smbd

echo ""
echo "=================================================="
echo "âœ“ Server Setup Complete!"
echo "=================================================="
echo ""
echo "Share Information:"
echo "  Name:     $SHARE_NAME"
echo "  Path:     $SHARE_PATH"
echo "  User:     $SGA_USER"
echo "  Group:    $SGA_GROUP"
echo ""
echo "Access from clients:"
echo "  //$(hostname -I | awk '{print $1}')/$SHARE_NAME"
echo ""
echo "Next steps:"
echo "  1. Copy SGA data to $SHARE_PATH/"
echo "  2. Test connection from client: smbclient //server/$SHARE_NAME -U $SGA_USER"
echo "  3. Mount on clients (see client_setup.sh)"
echo ""
echo "To view connected clients:"
echo "  smbstatus"
echo ""
