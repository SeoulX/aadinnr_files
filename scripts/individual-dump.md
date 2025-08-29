# Copy the mapping first
elasticdump \
  --input=http://192.168.3.104:30100/articles_2025_06_openai_large \
  --output=http://elastic-user:pU387ZnjqMml@ad61ed6a35aca426e96b748cf0c61f42-2146109277.us-west-1.elb.amazonaws.com:9200/articles_2025_06_openai_large \
  --type=mapping

# Copy the data with much smaller batch size
elasticdump \
  --input=http://192.168.3.104:30100/articles_2025_06_openai_large \
  --output=http://elastic-user:pU387ZnjqMml@ad61ed6a35aca426e96b748cf0c61f42-2146109277.us-west-1.elb.amazonaws.com:9200/articles_2025_06_openai_large \
  --type=data \
  --limit=1000 \
  --concurrency=1 \
  --timeout=120000