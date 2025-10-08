# 🔐 Security Checklist - MVP Production

## ⚠️ CRITICAL - Must Do Before Launch

### 1. Credentials & Secrets

- [ ] **Changed default database password** in `.env.production`
  ```bash
  # Generate secure password
  openssl rand -base64 32
  # Update POSTGRES_PASSWORD in .env.production
  ```

- [ ] **Removed default credentials** from `config/config.yaml`
  ```bash
  # Check for default passwords
  grep -r "changeme" config/
  grep -r "password: " config/config.yaml
  ```

- [ ] **Never committed** `.env.production` to git
  ```bash
  # Verify it's in .gitignore
  cat .gitignore | grep ".env.production"

  # If not, add it
  echo ".env.production" >> .gitignore
  echo "*.env.production" >> .gitignore
  ```

- [ ] **Deleted** `generated_api_keys.txt` (if it exists)
  ```bash
  rm -f generated_api_keys.txt
  ```

### 2. CORS & Origins

- [ ] **Restricted CORS origins** (no wildcards)

  In `config/config.yaml`:
  ```yaml
  security:
    allowed_origins:
      - "https://yourdomain.com"      # ✅ Good
      - "https://app.yourdomain.com"  # ✅ Good
      # - "*"                          # ❌ BAD - Remove this!
  ```

  Or in `.env.production`:
  ```bash
  ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
  ```

### 3. HTTPS/TLS

- [ ] **Enabled HTTPS** (required for production)
  ```bash
  # Install certbot
  sudo apt install certbot python3-certbot-nginx

  # Get SSL certificate
  sudo certbot --nginx -d voice.yourdomain.com

  # Verify auto-renewal
  sudo certbot renew --dry-run
  ```

- [ ] **Twilio webhook uses HTTPS** (not HTTP)
  - Verify in Twilio console: webhook URL starts with `https://`

### 4. Authentication

- [ ] **Enabled authentication** for admin endpoints

  In `config/config.yaml`:
  ```yaml
  security:
    enable_auth: true  # Change from false to true
  ```

- [ ] **API keys generated securely** (if using API key auth)
  ```bash
  # Generate production API keys
  python scripts/generate_api_keys.py
  # Save the key securely (password manager)
  # Never save to file!
  ```

---

## ✅ RECOMMENDED - Should Do Before Launch

### 5. Rate Limiting

- [ ] **Nginx rate limiting configured**

  Verify in `nginx.conf`:
  ```nginx
  limit_req_zone $binary_remote_addr zone=tts_limit:10m rate=2r/s;
  ```

- [ ] **Application rate limiting enabled**
  - Check Redis is running: `docker-compose ps redis`
  - Verify in logs: `docker-compose logs | grep "rate limit"`

### 6. Monitoring & Alerts

- [ ] **Health check endpoint working**
  ```bash
  curl https://yourdomain.com/health
  # Should return: {"status":"healthy",...}
  ```

- [ ] **Set up uptime monitoring**
  - Use: UptimeRobot, Pingdom, or StatusCake
  - Monitor: `https://yourdomain.com/health`
  - Alert on: status != "healthy"

- [ ] **Log monitoring configured**
  ```bash
  # Check logs are being written
  docker-compose exec chatterbox-tts ls -lh /app/logs/

  # Set up log rotation (already configured in docker-compose.yml)
  ```

### 7. Backups

- [ ] **Database backups enabled**
  ```bash
  # Create backup script
  cat > /usr/local/bin/backup-chatterbox.sh << 'EOF'
  #!/bin/bash
  BACKUP_DIR="/backups/chatterbox"
  mkdir -p $BACKUP_DIR
  docker-compose exec -T postgres pg_dump -U postgres chatterbox | gzip > "$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql.gz"
  find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete
  EOF

  chmod +x /usr/local/bin/backup-chatterbox.sh

  # Add to cron (daily at 2 AM)
  echo "0 2 * * * /usr/local/bin/backup-chatterbox.sh" | crontab -
  ```

- [ ] **Test backup restore procedure**
  ```bash
  # Create test backup
  docker-compose exec -T postgres pg_dump -U postgres chatterbox > test_backup.sql

  # Restore (on test instance!)
  # docker-compose exec -T postgres psql -U postgres chatterbox < test_backup.sql
  ```

### 8. Input Validation

- [ ] **Request size limits configured**

  In `nginx.conf`:
  ```nginx
  client_max_body_size 10M;
  ```

  In application code (already implemented):
  ```python
  if len(payload.text) > 2000:
      raise HTTPException(400, "Text too long")
  ```

- [ ] **File upload validation enabled** (for voice cloning)
  - Max file size: 50MB (already configured)
  - Allowed types: WAV, MP3 (already configured)

---

## 🔐 GOOD TO HAVE - Do Within First Month

### 9. Advanced Security

- [ ] **Implement API key rotation**
  ```sql
  -- Set expiration on API keys (30-90 days)
  UPDATE api_keys SET expires_at = NOW() + INTERVAL '90 days';
  ```

- [ ] **Add IP whitelisting** (for known customers)
  ```nginx
  # In nginx.conf
  allow 203.0.113.0/24;  # Customer IP range
  deny all;
  ```

- [ ] **Enable request logging to database**
  - Already configured in schema: `request_logs` table
  - Verify logs are being written:
    ```sql
    SELECT COUNT(*) FROM request_logs WHERE created_at > NOW() - INTERVAL '1 hour';
    ```

### 10. Compliance

- [ ] **Privacy policy published** (if collecting user data)
  - Required if storing: phone numbers, call recordings, transcripts

- [ ] **Terms of service published**
  - Define acceptable use
  - Prohibit: deepfakes, fraud, harassment

- [ ] **Voice consent system implemented** (for voice cloning)
  ```bash
  # Check schema exists
  docker-compose exec postgres psql -U postgres chatterbox -c "\d voice_consent"
  ```

### 11. Incident Response

- [ ] **Incident response plan documented**
  - Who to contact if breach detected
  - How to shut down system quickly
  - Communication plan for customers

- [ ] **Emergency shutdown procedure**
  ```bash
  # Quick shutdown
  docker-compose down

  # Block all traffic (if under attack)
  sudo ufw deny 8004
  sudo ufw deny 443
  ```

### 12. Regular Security Maintenance

- [ ] **Update dependencies monthly**
  ```bash
  # Check for updates
  pip list --outdated

  # Update requirements.txt
  pip install --upgrade -r requirements.txt
  pip freeze > requirements.txt
  ```

- [ ] **Review logs weekly** for suspicious activity
  ```bash
  # Check for failed auth attempts
  docker-compose logs | grep "Invalid API key"

  # Check for unusual traffic
  docker-compose logs | grep "Rate limit exceeded"
  ```

- [ ] **Security audit quarterly**
  - Review user permissions
  - Check for exposed credentials
  - Test backup restore
  - Verify SSL certificate expiration

---

## 🧪 Security Testing

### Run Security Tests

```bash
# Test HTTPS redirect
curl -I http://yourdomain.com
# Should return: 301 Moved Permanently, Location: https://

# Test CORS
curl -H "Origin: https://evil.com" https://yourdomain.com/health
# Should NOT include: Access-Control-Allow-Origin: https://evil.com

# Test rate limiting
for i in {1..100}; do curl https://yourdomain.com/health & done
# Some requests should return: 429 Too Many Requests

# Test authentication (if enabled)
curl https://yourdomain.com/admin
# Should return: 401 Unauthorized (without credentials)
```

### Vulnerability Scanning

```bash
# Install nikto (web vulnerability scanner)
sudo apt install nikto

# Scan your server
nikto -h https://yourdomain.com

# Check for known CVEs
docker-compose exec chatterbox-tts pip install safety
docker-compose exec chatterbox-tts safety check
```

---

## 📋 Quick Security Audit

Run this command to check common issues:

```bash
#!/bin/bash
echo "🔐 Security Audit - Quick Check"
echo ""

# Check for default passwords
echo "[1/6] Checking for default passwords..."
if grep -q "changeme" .env.production 2>/dev/null; then
    echo "  ❌ Default password found in .env.production"
else
    echo "  ✅ No default passwords in .env.production"
fi

# Check CORS configuration
echo "[2/6] Checking CORS configuration..."
if grep -q 'allowed_origins:.*"\*"' config/config.yaml 2>/dev/null; then
    echo "  ❌ Wildcard CORS enabled (security risk)"
else
    echo "  ✅ CORS properly restricted"
fi

# Check if .env is ignored by git
echo "[3/6] Checking .gitignore..."
if grep -q ".env.production" .gitignore; then
    echo "  ✅ .env.production in .gitignore"
else
    echo "  ❌ .env.production NOT in .gitignore"
fi

# Check if HTTPS is configured
echo "[4/6] Checking HTTPS configuration..."
if [ -f "/etc/letsencrypt/live/*/fullchain.pem" ]; then
    echo "  ✅ SSL certificate found"
else
    echo "  ⚠️  No SSL certificate (use certbot)"
fi

# Check if services are running
echo "[5/6] Checking services..."
if docker-compose ps | grep -q "Up"; then
    echo "  ✅ Services are running"
else
    echo "  ❌ Services are not running"
fi

# Check database password strength
echo "[6/6] Checking database password strength..."
if [ -f .env.production ]; then
    PW_LENGTH=$(grep "POSTGRES_PASSWORD=" .env.production | cut -d'=' -f2 | wc -c)
    if [ $PW_LENGTH -gt 20 ]; then
        echo "  ✅ Strong database password ($PW_LENGTH chars)"
    else
        echo "  ❌ Weak database password ($PW_LENGTH chars) - use at least 20"
    fi
fi

echo ""
echo "✅ Security audit complete"
```

Save this as `security_audit.sh` and run before launch:
```bash
chmod +x security_audit.sh
./security_audit.sh
```

---

## 🚨 What to Do If Compromised

If you suspect a security breach:

1. **Immediately shut down**
   ```bash
   docker-compose down
   ```

2. **Revoke all API keys**
   ```bash
   docker-compose exec postgres psql -U postgres chatterbox -c "UPDATE api_keys SET status='revoked';"
   ```

3. **Change all passwords**
   - Database password
   - Twilio auth token
   - LLM API keys

4. **Review logs** for suspicious activity
   ```bash
   docker-compose logs --since 24h > incident_logs.txt
   ```

5. **Notify affected users** (if data was accessed)

6. **Contact Twilio** to report potential fraud

---

## ✅ Pre-Launch Security Checklist

Print this and check off before going live:

```
MVP PRODUCTION SECURITY CHECKLIST
================================

CRITICAL (Must Complete):
[ ] Changed default database password
[ ] Removed default credentials from config files
[ ] .env.production NOT in git
[ ] CORS restricted to specific domains (no *)
[ ] HTTPS/SSL enabled
[ ] Twilio webhook uses HTTPS
[ ] deleted generated_api_keys.txt file

RECOMMENDED (Should Complete):
[ ] Rate limiting configured and tested
[ ] Health check endpoint working
[ ] Uptime monitoring set up
[ ] Database backups enabled
[ ] Request size limits configured
[ ] Log monitoring enabled

GOOD TO HAVE (Complete Soon):
[ ] API key rotation policy
[ ] Privacy policy published
[ ] Terms of service published
[ ] Incident response plan documented
[ ] Regular security updates scheduled

Signed: _______________  Date: __________
```

---

**🔒 Security is not a one-time task. Review this checklist monthly!**
