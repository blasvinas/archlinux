notify-send "Starting backup"
rclone sync /home/blas/Dropbox/ /home/blas/OneDrive/   --exclude ".dropbox.cache/**"
notify-send "Backup completed"
