#!/bin/bash

# This script creates a complete working microservices project structure
# Run this after cloning the template repository

echo "Creating complete e-commerce microservices project structure..."

# Create Product Service structure
echo "Setting up Product Service..."
mkdir -p product-service/src/main/java/com/ecommerce/product/{controller,service,model,repository,config}
mkdir -p product-service/src/main/resources
mkdir -p product-service/src/test/java/com/ecommerce/product

# Create Order Service structure  
echo "Setting up Order Service..."
mkdir -p order-service/src/main/java/com/ecommerce/order/{controller,service,model,repository,config}
mkdir -p order-service/src/main/resources
mkdir -p order-service/src/test/java/com/ecommerce/order

# Create API Gateway structure
echo "Setting up API Gateway..."
mkdir -p api-gateway/src/main/java/com/ecommerce/gateway/config
mkdir -p api-gateway/src/main/resources
mkdir -p api-gateway/src/test/java/com/ecommerce/gateway

echo "✅ Project structure created successfully!"
echo "Next steps:"
echo "1. Update YOUR-PROJECT-ID in k8s deployment files"
echo "2. Add GitHub secrets as per SETUP_CHECKLIST.md"
echo "3. Build and deploy!"

