# VaultSwap Hook Monitoring Guide

This guide covers monitoring and observability for VaultSwap Hook.

## Table of Contents

- [Overview](#overview)
- [Monitoring Setup](#monitoring-setup)
- [Metrics Collection](#metrics-collection)
- [Logging](#logging)
- [Alerting](#alerting)
- [Dashboards](#dashboards)
- [Health Checks](#health-checks)
- [Performance Monitoring](#performance-monitoring)

## Overview

Monitoring VaultSwap Hook is essential for:
- **System Health**: Ensure all components are running properly
- **Performance**: Monitor system performance and identify bottlenecks
- **Security**: Detect security issues and anomalies
- **Reliability**: Maintain high availability and uptime
- **Debugging**: Troubleshoot issues quickly and effectively

## Monitoring Setup

### 1. Prerequisites

**Required Software**:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Node Exporter**: System metrics
- **cAdvisor**: Container metrics
- **Alertmanager**: Alert management

**Installation**:
```bash
# Install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-2.45.0.linux-amd64.tar.gz
cd prometheus-2.45.0.linux-amd64

# Install Grafana
wget https://dl.grafana.com/oss/release/grafana-10.0.0.linux-amd64.tar.gz
tar -zxvf grafana-10.0.0.linux-amd64.tar.gz
cd grafana-10.0.0

# Install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
cd node_exporter-1.6.1.linux-amd64
```

### 2. Configuration

**Prometheus Configuration** (`prometheus.yml`):
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "vaultswap_rules.yml"

scrape_configs:
  - job_name: 'vaultswap-hook'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 5s

  - job_name: 'vaultswap-avs'
    static_configs:
      - targets: ['localhost:9091']
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
    scrape_interval: 15s

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']
    scrape_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

**Grafana Configuration** (`grafana.ini`):
```ini
[server]
http_port = 3000
root_url = http://localhost:3000

[security]
admin_user = admin
admin_password = admin

[datasources]
default = prometheus
```

### 3. Start Services

```bash
# Start Prometheus
./prometheus --config.file=prometheus.yml

# Start Grafana
./bin/grafana-server

# Start Node Exporter
./node_exporter

# Start cAdvisor
docker run -d --name=cadvisor -p 8080:8080 -v /:/rootfs:ro -v /var/run:/var/run:ro -v /sys:/sys:ro -v /var/lib/docker/:/var/lib/docker:ro -v /dev/disk/:/dev/disk:ro gcr.io/cadvisor/cadvisor:latest
```

## Metrics Collection

### 1. Smart Contract Metrics

**Order Processing Metrics**:
```typescript
// Order creation rate
const orderCreationRate = new prometheus.Counter({
  name: 'vaultswap_orders_created_total',
  help: 'Total number of orders created',
  labelNames: ['token_in', 'token_out', 'user']
});

// Order execution rate
const orderExecutionRate = new prometheus.Counter({
  name: 'vaultswap_orders_executed_total',
  help: 'Total number of orders executed',
  labelNames: ['token_in', 'token_out', 'executor']
});

// Order failure rate
const orderFailureRate = new prometheus.Counter({
  name: 'vaultswap_orders_failed_total',
  help: 'Total number of order failures',
  labelNames: ['reason', 'token_in', 'token_out']
});

// Order execution time
const orderExecutionTime = new prometheus.Histogram({
  name: 'vaultswap_order_execution_duration_seconds',
  help: 'Time taken to execute orders',
  labelNames: ['token_in', 'token_out'],
  buckets: [0.1, 0.5, 1, 2, 5, 10, 30, 60]
});
```

**MEV Protection Metrics**:
```typescript
// MEV protection effectiveness
const mevProtectionEffectiveness = new prometheus.Gauge({
  name: 'vaultswap_mev_protection_effectiveness',
  help: 'MEV protection effectiveness (0-1)',
  labelNames: ['protection_level']
});

// Decoy orders generated
const decoyOrdersGenerated = new prometheus.Counter({
  name: 'vaultswap_decoy_orders_generated_total',
  help: 'Total number of decoy orders generated',
  labelNames: ['protection_level']
});

// MEV attacks prevented
const mevAttacksPrevented = new prometheus.Counter({
  name: 'vaultswap_mev_attacks_prevented_total',
  help: 'Total number of MEV attacks prevented',
  labelNames: ['attack_type']
});
```

**Privacy Metrics**:
```typescript
// FHE operations
const fheOperations = new prometheus.Counter({
  name: 'vaultswap_fhe_operations_total',
  help: 'Total number of FHE operations',
  labelNames: ['operation_type', 'success']
});

// Privacy level
const privacyLevel = new prometheus.Gauge({
  name: 'vaultswap_privacy_level',
  help: 'Current privacy level (0-5)',
  labelNames: ['feature']
});

// Encrypted operations
const encryptedOperations = new prometheus.Counter({
  name: 'vaultswap_encrypted_operations_total',
  help: 'Total number of encrypted operations',
  labelNames: ['operation_type']
});
```

### 2. AVS Metrics

**Task Processing Metrics**:
```go
// Task processing rate
var taskProcessingRate = prometheus.NewCounterVec(
    prometheus.CounterOpts{
        Name: "vaultswap_tasks_processed_total",
        Help: "Total number of tasks processed",
    },
    []string{"task_type", "status"},
)

// Task processing time
var taskProcessingTime = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{
        Name: "vaultswap_task_processing_duration_seconds",
        Help: "Time taken to process tasks",
        Buckets: []float64{0.1, 0.5, 1, 2, 5, 10, 30, 60},
    },
    []string{"task_type"},
)

// Task queue size
var taskQueueSize = prometheus.NewGaugeVec(
    prometheus.GaugeOpts{
        Name: "vaultswap_task_queue_size",
        Help: "Current size of task queue",
    },
    []string{"queue_type"},
)
```

**Cross-Chain Metrics**:
```go
// Cross-chain messages
var crossChainMessages = prometheus.NewCounterVec(
    prometheus.CounterOpts{
        Name: "vaultswap_cross_chain_messages_total",
        Help: "Total number of cross-chain messages",
    },
    []string{"direction", "status"},
)

// Cross-chain sync time
var crossChainSyncTime = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{
        Name: "vaultswap_cross_chain_sync_duration_seconds",
        Help: "Time taken to sync cross-chain data",
        Buckets: []float64{0.1, 0.5, 1, 2, 5, 10, 30, 60},
    },
    []string{"chain"},
)
```

### 3. System Metrics

**Resource Usage**:
```bash
# CPU usage
node_cpu_seconds_total

# Memory usage
node_memory_MemTotal_bytes
node_memory_MemAvailable_bytes

# Disk usage
node_filesystem_size_bytes
node_filesystem_avail_bytes

# Network usage
node_network_receive_bytes_total
node_network_transmit_bytes_total
```

**Application Metrics**:
```bash
# HTTP requests
http_requests_total
http_request_duration_seconds

# Database connections
database_connections_active
database_connections_idle

# Cache hit rate
cache_hits_total
cache_misses_total
```

## Logging

### 1. Log Configuration

**Log Levels**:
- **DEBUG**: Detailed information for debugging
- **INFO**: General information about system operation
- **WARN**: Warning messages for potential issues
- **ERROR**: Error messages for failed operations
- **FATAL**: Critical errors that cause system failure

**Log Format**:
```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "level": "INFO",
  "message": "Order created successfully",
  "order_id": "0x...",
  "user": "0x...",
  "token_in": "0x...",
  "token_out": "0x...",
  "amount_in": "1000000000000000000",
  "min_amount_out": "950000000000000000",
  "deadline": 1704067200
}
```

### 2. Log Categories

**Smart Contract Logs**:
```typescript
// Order events
logger.info('Order created', {
  orderId,
  user,
  tokenIn,
  tokenOut,
  amountIn,
  minAmountOut,
  deadline
});

// MEV protection events
logger.info('MEV protection activated', {
  protectionLevel,
  decoyOrdersGenerated,
  attackPrevented
});

// Privacy events
logger.info('FHE operation completed', {
  operationType,
  success,
  duration
});
```

**AVS Logs**:
```go
// Task processing
log.Info("Task processed successfully",
    "task_id", taskID,
    "task_type", taskType,
    "duration", duration,
    "status", status,
)

// Cross-chain events
log.Info("Cross-chain message sent",
    "message_id", messageID,
    "direction", direction,
    "chain", chain,
    "status", status,
)
```

### 3. Log Aggregation

**ELK Stack Setup**:
```yaml
# docker-compose.yml
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.8.0
    environment:
      - discovery.type=single-node
    ports:
      - "9200:9200"

  logstash:
    image: docker.elastic.co/logstash/logstash:8.8.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5044:5044"

  kibana:
    image: docker.elastic.co/kibana/kibana:8.8.0
    ports:
      - "5601:5601"
```

## Alerting

### 1. Alert Rules

**Prometheus Alert Rules** (`vaultswap_rules.yml`):
```yaml
groups:
  - name: vaultswap.rules
    rules:
      # Order processing alerts
      - alert: HighOrderFailureRate
        expr: rate(vaultswap_orders_failed_total[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High order failure rate detected"
          description: "Order failure rate is {{ $value }} failures per second"

      # MEV protection alerts
      - alert: MEVProtectionFailure
        expr: vaultswap_mev_protection_effectiveness < 0.8
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "MEV protection effectiveness low"
          description: "MEV protection effectiveness is {{ $value }}"

      # System resource alerts
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is {{ $value }}%"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is {{ $value }}%"
```

### 2. Alert Channels

**Slack Integration**:
```yaml
# alertmanager.yml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'slack-notifications'

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - channel: '#vaultswap-alerts'
        title: 'VaultSwap Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

**Email Integration**:
```yaml
receivers:
  - name: 'email-notifications'
    email_configs:
      - to: 'alerts@vaultswap.io'
        from: 'alerts@vaultswap.io'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'alerts@vaultswap.io'
        auth_password: 'your_password'
        subject: 'VaultSwap Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
```

## Dashboards

### 1. Grafana Dashboard

**Main Dashboard**:
```json
{
  "dashboard": {
    "title": "VaultSwap Hook Overview",
    "panels": [
      {
        "title": "Order Processing Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(vaultswap_orders_created_total[5m])",
            "legendFormat": "Orders Created"
          },
          {
            "expr": "rate(vaultswap_orders_executed_total[5m])",
            "legendFormat": "Orders Executed"
          }
        ]
      },
      {
        "title": "MEV Protection Effectiveness",
        "type": "singlestat",
        "targets": [
          {
            "expr": "vaultswap_mev_protection_effectiveness",
            "legendFormat": "Effectiveness"
          }
        ]
      },
      {
        "title": "System Resources",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %"
          },
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "Memory Usage %"
          }
        ]
      }
    ]
  }
}
```

### 2. Custom Dashboards

**Order Analytics Dashboard**:
- Order creation trends
- Order execution success rate
- Order failure analysis
- Token pair popularity

**MEV Protection Dashboard**:
- MEV protection effectiveness
- Decoy order generation
- Attack prevention metrics
- Protection level distribution

**System Health Dashboard**:
- Resource utilization
- Service availability
- Error rates
- Performance metrics

## Health Checks

### 1. Application Health Checks

**Smart Contract Health**:
```typescript
// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Check contract connectivity
    const name = await hook.name();
    
    // Check order processing
    const orderCount = await hook.getOrderCount();
    
    // Check MEV protection
    const mevLevel = await hook.getMEVProtectionLevel();
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      contracts: {
        hook: { connected: true, name },
        orderCount
      },
      mev: {
        protectionLevel: mevLevel
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});
```

**AVS Health Check**:
```go
// Health check endpoint
func healthCheck(w http.ResponseWriter, r *http.Request) {
    // Check performer status
    status := performer.GetStatus()
    
    // Check task queue
    queueSize := performer.GetQueueSize()
    
    // Check cross-chain connectivity
    l1Connected := performer.CheckL1Connection()
    l2Connected := performer.CheckL2Connection()
    
    if status == "running" && l1Connected && l2Connected {
        w.WriteHeader(http.StatusOK)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status": "healthy",
            "timestamp": time.Now().ISO8601(),
            "performer": map[string]interface{}{
                "status": status,
                "queue_size": queueSize,
            },
            "connectivity": map[string]interface{}{
                "l1": l1Connected,
                "l2": l2Connected,
            },
        })
    } else {
        w.WriteHeader(http.StatusServiceUnavailable)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status": "unhealthy",
            "timestamp": time.Now().ISO8601(),
            "error": "Service unavailable",
        })
    }
}
```

### 2. System Health Checks

**Resource Health**:
```bash
#!/bin/bash
# health_check.sh

# Check CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "WARNING: High CPU usage: $CPU_USAGE%"
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}')
if (( $(echo "$MEMORY_USAGE > 85" | bc -l) )); then
    echo "WARNING: High memory usage: $MEMORY_USAGE%"
fi

# Check disk usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 85 ]; then
    echo "WARNING: High disk usage: $DISK_USAGE%"
fi

# Check network connectivity
if ! ping -c 1 google.com > /dev/null 2>&1; then
    echo "WARNING: Network connectivity issues"
fi
```

## Performance Monitoring

### 1. Key Performance Indicators (KPIs)

**Order Processing KPIs**:
- Order creation rate (orders/second)
- Order execution rate (orders/second)
- Order success rate (%)
- Average order execution time (seconds)
- Order failure rate (%)

**MEV Protection KPIs**:
- MEV protection effectiveness (0-1)
- Decoy order generation rate (orders/second)
- Attack prevention rate (%)
- Protection level distribution

**System Performance KPIs**:
- Response time (milliseconds)
- Throughput (requests/second)
- Error rate (%)
- Availability (%)

### 2. Performance Optimization

**Database Optimization**:
```sql
-- Index optimization
CREATE INDEX idx_orders_user ON orders(user);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Query optimization
EXPLAIN ANALYZE SELECT * FROM orders WHERE user = ? AND status = ?;
```

**Caching Strategy**:
```typescript
// Redis caching
const redis = new Redis({
  host: 'localhost',
  port: 6379,
  db: 0
});

// Cache order data
const cacheOrder = async (orderId: string, orderData: any) => {
  await redis.setex(`order:${orderId}`, 3600, JSON.stringify(orderData));
};

// Get cached order
const getCachedOrder = async (orderId: string) => {
  const cached = await redis.get(`order:${orderId}`);
  return cached ? JSON.parse(cached) : null;
};
```

## Best Practices

### 1. Monitoring Best Practices

- **Set appropriate alert thresholds**
- **Monitor both technical and business metrics**
- **Use multiple alert channels**
- **Regularly review and update dashboards**
- **Test alerting systems regularly**

### 2. Logging Best Practices

- **Use structured logging**
- **Include relevant context**
- **Set appropriate log levels**
- **Rotate logs regularly**
- **Monitor log volume**

### 3. Performance Best Practices

- **Monitor key performance indicators**
- **Set performance baselines**
- **Optimize based on metrics**
- **Regularly review performance**
- **Plan for scaling**

---

**Need help with monitoring?** Check out our [Troubleshooting Guide](TROUBLESHOOTING.md) or join our [Discord](https://discord.gg/vaultswap).

**Want to contribute?** See our [Contributing Guide](CONTRIBUTING.md).

**Have questions?** Visit our [FAQ](FAQ.md) or [Support](SUPPORT.md) page.

---

*This monitoring guide is regularly updated. Last updated: January 1, 2024*
