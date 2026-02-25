#!/bin/bash

# Create Product Service minimal files
mkdir -p product-service/src/main/java/com/ecommerce/product
mkdir -p product-service/src/main/resources

cat > product-service/src/main/java/com/ecommerce/product/ProductServiceApplication.java << 'JAVA'
package com.ecommerce.product;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
@SpringBootApplication
public class ProductServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(ProductServiceApplication.class, args);
    }
}
JAVA

cat > product-service/src/main/resources/application.yml << 'YAML'
spring:
  application:
    name: product-service
server:
  port: 8081
YAML

# Create Order Service minimal files
mkdir -p order-service/src/main/java/com/ecommerce/order
mkdir -p order-service/src/main/resources

cat > order-service/src/main/java/com/ecommerce/order/OrderServiceApplication.java << 'JAVA'
package com.ecommerce.order;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
@SpringBootApplication
public class OrderServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(OrderServiceApplication.class, args);
    }
}
JAVA

cat > order-service/src/main/resources/application.yml << 'YAML'
spring:
  application:
    name: order-service
server:
  port: 8082
YAML

# Create API Gateway minimal files
mkdir -p api-gateway/src/main/java/com/ecommerce/gateway
mkdir -p api-gateway/src/main/resources

cat > api-gateway/src/main/java/com/ecommerce/gateway/ApiGatewayApplication.java << 'JAVA'
package com.ecommerce.gateway;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
@SpringBootApplication
public class ApiGatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }
}
JAVA

cat > api-gateway/src/main/resources/application.yml << 'YAML'
spring:
  application:
    name: api-gateway
server:
  port: 8080
YAML

echo "✅ Minimal source files created!"
