# CTFd Docker Setup

This guide will help you run CTFd using Docker with persistent data storage. When you stop and restart the containers, all your data (database, uploads, logs, cache) will be preserved.

## Prerequisites

- Docker Desktop installed on Windows
- Docker Compose (included with Docker Desktop)

## Quick Start

1. **Clone and navigate to the CTFd directory:**
   ```powershell
   cd c:\Users\PRANXTEN\Documents\CTFPanel
   ```

2. **Create environment file:**
   ```powershell
   Copy-Item .env.example .env
   ```

3. **Edit the .env file** and change the default passwords:
   - Open `.env` in your preferred text editor
   - Change `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`, and `SECRET_KEY` to secure values

4. **Start CTFd:**
   ```powershell
   docker-compose up -d
   ```

5. **Access CTFd:**
   - Open your browser and go to `http://localhost`
   - Follow the setup wizard to configure your CTF

6. **Stop CTFd:**
   ```powershell
   docker-compose down
   ```

## Data Persistence

Your CTFd data is stored in the `.data/` directory with the following structure:
```
.data/
├── mysql/          # Database files
├── redis/          # Cache data
├── CTFd/
│   ├── logs/       # CTFd logs
│   └── uploads/    # Uploaded files
```

**Important:** Never delete the `.data/` directory unless you want to permanently lose all your CTF data.

## Services

The Docker setup includes:
- **ctfd**: Main CTFd application (port 8000)
- **nginx**: Reverse proxy (port 80)
- **db**: MariaDB database (internal)
- **cache**: Redis cache (internal)

## Configuration

### Environment Variables (.env file)

| Variable | Description | Default |
|----------|-------------|---------|
| `MYSQL_ROOT_PASSWORD` | MySQL root password | ctfd_root_password_change_me |
| `MYSQL_PASSWORD` | CTFd database password | ctfd_password_change_me |
| `SECRET_KEY` | Flask secret key | your_secret_key_here_change_me |
| `WORKERS` | Number of gunicorn workers | 1 |

### CTFd Configuration (CTFd/config.ini)

You can also modify `CTFd/config.ini` for additional configuration options like:
- Email settings
- Upload providers (filesystem/S3)
- Security settings
- Theme settings

## Common Commands

### View logs
```powershell
# All services
docker-compose logs

# Specific service
docker-compose logs ctfd
docker-compose logs db
```

### Restart services
```powershell
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart ctfd
```

### Update CTFd
```powershell
# Stop containers
docker-compose down

# Rebuild CTFd image
docker-compose build ctfd

# Start with new image
docker-compose up -d
```

### Backup Data
```powershell
# Create backup directory
mkdir backups

# Backup database
docker-compose exec db mysqldump -u ctfd -p ctfd > backups/ctfd_backup_$(Get-Date -Format "yyyy-MM-dd").sql

# Backup entire data directory
Compress-Archive -Path .data -DestinationPath "backups/ctfd_data_backup_$(Get-Date -Format 'yyyy-MM-dd').zip"
```

### Database Access
```powershell
# Access MySQL shell
docker-compose exec db mysql -u ctfd -p ctfd
```

## Troubleshooting

### Port Already in Use
If port 80 is already in use, modify `docker-compose.yml`:
```yaml
nginx:
  ports:
    - "8080:80"  # Change to different port
```

### Permission Issues
On Windows, if you encounter permission issues with volumes:
```powershell
# Ensure Docker Desktop has access to your drive
# Go to Docker Desktop Settings > Resources > File Sharing
```

### Database Connection Issues
1. Ensure the database container is healthy:
   ```powershell
   docker-compose ps
   ```

2. Check database logs:
   ```powershell
   docker-compose logs db
   ```

### Reset Everything
To start fresh (⚠️ **This will delete all data**):
```powershell
docker-compose down -v
Remove-Item -Recurse -Force .data
docker-compose up -d
```

## Security Notes

1. **Change default passwords** in the `.env` file
2. **Use HTTPS in production** by configuring SSL certificates in nginx
3. **Firewall rules** - only expose necessary ports (80/443)
4. **Regular backups** of the `.data` directory
5. **Keep Docker images updated** by running `docker-compose pull` periodically

## Production Considerations

For production deployments:
1. Use a reverse proxy with SSL termination
2. Set up automated backups
3. Monitor resource usage
4. Configure log rotation
5. Use Docker secrets for sensitive data
6. Set up health checks
7. Consider using external managed databases

## Support

For CTFd-specific issues, refer to:
- [CTFd Documentation](https://docs.ctfd.io/)
- [CTFd GitHub Repository](https://github.com/CTFd/CTFd)
