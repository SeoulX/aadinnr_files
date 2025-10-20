# ELK Stack Troubleshooting Guide

## Common Issues and Solutions

### 1. Pods Not Starting

**Problem**: Pods are stuck in `Pending` or `CrashLoopBackOff` state.

**Solutions**:
```bash
# Check pod status
kubectl get pods -n elastic-stack

# Check pod logs
kubectl logs -f deployment/elasticsearch -n elastic-stack
kubectl logs -f deployment/logstash -n elastic-stack
kubectl logs -f deployment/kibana -n elastic-stack

# Check pod events
kubectl describe pod <pod-name> -n elastic-stack
```

**Common causes**:
- Insufficient resources (CPU/Memory)
- Storage issues
- Image pull problems
- Configuration errors

### 2. Elasticsearch Issues

**Problem**: Elasticsearch not responding or cluster health issues.

**Solutions**:
```bash
# Check cluster health
kubectl exec -it deployment/elasticsearch -n elastic-stack -- curl -X GET "localhost:9200/_cluster/health?pretty"

# Check indices
kubectl exec -it deployment/elasticsearch -n elastic-stack -- curl -X GET "localhost:9200/_cat/indices?v"

# Check node info
kubectl exec -it deployment/elasticsearch -n elastic-stack -- curl -X GET "localhost:9200/_nodes?pretty"
```

**Common fixes**:
- Increase memory limits in deployment.yaml
- Check persistent volume claims
- Verify network connectivity

### 3. Logstash Issues

**Problem**: Logstash not processing logs or connection issues.

**Solutions**:
```bash
# Check Logstash status
kubectl exec -it deployment/logstash -n elastic-stack -- curl -X GET "localhost:9600/_node/stats?pretty"

# Check pipeline status
kubectl exec -it deployment/logstash -n elastic-stack -- curl -X GET "localhost:9600/_node/pipelines?pretty"

# Test configuration
kubectl exec -it deployment/logstash -n elastic-stack -- /usr/share/logstash/bin/logstash --config.test_and_exit --path.config=/usr/share/logstash/pipeline/
```

**Common fixes**:
- Verify Elasticsearch connectivity
- Check pipeline configuration
- Increase memory limits

### 4. Kibana Issues

**Problem**: Kibana not loading or connection to Elasticsearch failed.

**Solutions**:
```bash
# Check Kibana status
kubectl exec -it deployment/kibana -n elastic-stack -- curl -X GET "localhost:5601/api/status"

# Check Elasticsearch connection
kubectl exec -it deployment/kibana -n elastic-stack -- curl -X GET "localhost:5601/api/elasticsearch/status"
```

**Common fixes**:
- Verify Elasticsearch URL in config
- Check network connectivity
- Clear browser cache

### 5. Storage Issues

**Problem**: Persistent volume claims not bound or storage full.

**Solutions**:
```bash
# Check PVC status
kubectl get pvc -n elastic-stack

# Check PV status
kubectl get pv

# Check storage class
kubectl get storageclass
```

**Common fixes**:
- Ensure storage class exists
- Check available storage space
- Verify node storage capacity

### 6. Network Issues

**Problem**: Services not accessible or connection timeouts.

**Solutions**:
```bash
# Check service endpoints
kubectl get endpoints -n elastic-stack

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup elasticsearch.elastic-stack.svc.cluster.local

# Check ingress status
kubectl get ingress -n elastic-stack
```

### 7. Resource Issues

**Problem**: Pods being evicted or OOMKilled.

**Solutions**:
```bash
# Check resource usage
kubectl top pods -n elastic-stack

# Check node resources
kubectl top nodes

# Check resource limits
kubectl describe deployment elasticsearch -n elastic-stack
```

**Common fixes**:
- Increase resource limits
- Add more nodes to cluster
- Optimize application resource usage

## Performance Tuning

### Elasticsearch Tuning
```yaml
# In elasticsearch deployment.yaml
env:
- name: "ES_JAVA_OPTS"
  value: "-Xms2g -Xmx2g"  # Adjust based on available memory
```

### Logstash Tuning
```yaml
# In logstash deployment.yaml
env:
- name: "LS_JAVA_OPTS"
  value: "-Xms1g -Xmx1g"  # Adjust based on available memory
```

### Kibana Tuning
```yaml
# In kibana deployment.yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

## Monitoring Commands

```bash
# Watch pod status
kubectl get pods -n elastic-stack -w

# Monitor logs
kubectl logs -f deployment/elasticsearch -n elastic-stack

# Check resource usage
kubectl top pods -n elastic-stack

# Check events
kubectl get events -n elastic-stack --sort-by='.lastTimestamp'
```

## Useful Debugging Commands

```bash
# Port forward for direct access
kubectl port-forward svc/elasticsearch 9200:9200 -n elastic-stack
kubectl port-forward svc/kibana 5601:5601 -n elastic-stack
kubectl port-forward svc/logstash 8080:8080 -n elastic-stack

# Execute commands in pods
kubectl exec -it deployment/elasticsearch -n elastic-stack -- /bin/bash
kubectl exec -it deployment/logstash -n elastic-stack -- /bin/bash
kubectl exec -it deployment/kibana -n elastic-stack -- /bin/bash

# Check configuration
kubectl get configmap -n elastic-stack
kubectl describe configmap elasticsearch-config -n elastic-stack
```

## Getting Help

If you encounter issues not covered in this guide:

1. Check the official Elastic documentation
2. Review Kubernetes logs and events
3. Verify your cluster resources and configuration
4. Test with minimal configuration first
5. Consider using the official Elastic Cloud for production workloads
