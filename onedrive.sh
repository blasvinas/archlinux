rclone --vfs-cache-mode writes mount OneDrive:/Linux ~/OneDrive --daemon
notify-send "OneDrive connected" 
sleep 3
notify-send "Starting backup"
rclone sync /home/blas/Dropbox/ /home/blas/OneDrive/   --exclude ".dropbox.cache/**"
notify-send "Backup completed"
