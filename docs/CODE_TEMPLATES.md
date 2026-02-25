# Complete Code Templates

This document contains all the source code needed for the microservices. Create these files in your project.

## Product Service Files

### 1. `product-service/pom.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.ecommerce</groupId>
        <artifactId>ecommerce-microservices</artifactId>
        <version>1.0.0</version>
    </parent>

    <artifactId>product-service</artifactId>
    <version>1.0.0</version>
    <name>Product Service</name>
    <description>Product management microservice</description>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
        <finalName>app</finalName>
    </build>
</project>
```

### 2. `product-service/Dockerfile`

```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/app.jar app.jar
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 3. `product-service/src/main/resources/application.yml`

```yaml
spring:
  application:
    name: product-service
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}

---
spring:
  config:
    activate:
      on-profile: dev
  datasource:
    url: jdbc:h2:mem:productdb
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: true
  h2:
    console:
      enabled: true

server:
  port: 8081

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      probes:
        enabled: true
      show-details: always

---
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: jdbc:h2:mem:productdb
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: false

server:
  port: ${SERVER_PORT:8081}

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      probes:
        enabled: true
```

### 4. `product-service/src/main/java/com/ecommerce/product/ProductServiceApplication.java`

```java
package com.ecommerce.product;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ProductServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(ProductServiceApplication.java, args);
    }
}
```

### 5. `product-service/src/main/java/com/ecommerce/product/model/Product.java`

```java
package com.ecommerce.product.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Entity
@Table(name = "products")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String name;
    private String description;
    private BigDecimal price;
    private Integer stock;
}
```

### 6. `product-service/src/main/java/com/ecommerce/product/repository/ProductRepository.java`

```java
package com.ecommerce.product.repository;

import com.ecommerce.product.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
}
```

### 7. `product-service/src/main/java/com/ecommerce/product/service/ProductService.java`

```java
package com.ecommerce.product.service;

import com.ecommerce.product.model.Product;
import com.ecommerce.product.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ProductService {
    private final ProductRepository productRepository;

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    public Optional<Product> getProductById(Long id) {
        return productRepository.findById(id);
    }

    public Product createProduct(Product product) {
        return productRepository.save(product);
    }

    public Product updateProduct(Long id, Product productDetails) {
        return productRepository.findById(id)
                .map(product -> {
                    product.setName(productDetails.getName());
                    product.setDescription(productDetails.getDescription());
                    product.setPrice(productDetails.getPrice());
                    product.setStock(productDetails.getStock());
                    return productRepository.save(product);
                })
                .orElseThrow(() -> new RuntimeException("Product not found"));
    }

    public void deleteProduct(Long id) {
        productRepository.deleteById(id);
    }
}
```

### 8. `product-service/src/main/java/com/ecommerce/product/controller/ProductController.java`

```java
package com.ecommerce.product.controller;

import com.ecommerce.product.model.Product;
import com.ecommerce.product.service.ProductService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/products")
@RequiredArgsConstructor
public class ProductController {
    private final ProductService productService;

    @GetMapping
    public ResponseEntity<List<Product>> getAllProducts() {
        return ResponseEntity.ok(productService.getAllProducts());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Product> getProductById(@PathVariable Long id) {
        return productService.getProductById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Product> createProduct(@RequestBody Product product) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(productService.createProduct(product));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Product> updateProduct(
            @PathVariable Long id,
            @RequestBody Product product) {
        try {
            return ResponseEntity.ok(productService.updateProduct(id, product));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable Long id) {
        productService.deleteProduct(id);
        return ResponseEntity.noContent().build();
    }
}
```

---

## Order Service Files

### 1. `order-service/pom.xml`

Same structure as Product Service, change artifactId to `order-service`

### 2. `order-service/Dockerfile`

```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/app.jar app.jar
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 3. `order-service/src/main/resources/application.yml`

```yaml
spring:
  application:
    name: order-service
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}

---
spring:
  config:
    activate:
      on-profile: dev
  datasource:
    url: jdbc:h2:mem:orderdb
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: true
  h2:
    console:
      enabled: true

server:
  port: 8082

product:
  service:
    url: http://localhost:8081

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      probes:
        enabled: true
      show-details: always

---
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: jdbc:h2:mem:orderdb
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create-drop
    show-sql: false

server:
  port: ${SERVER_PORT:8082}

product:
  service:
    url: ${PRODUCT_SERVICE_URL:http://product-service:8081}

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      probes:
        enabled: true
```

### 4. Order Service Java Files

Follow similar pattern as Product Service:
- `OrderServiceApplication.java`
- `Order.java` (model)
- `OrderRepository.java`
- `OrderService.java`
- `OrderController.java`

---

## API Gateway Files

### 1. `api-gateway/pom.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.ecommerce</groupId>
        <artifactId>ecommerce-microservices</artifactId>
        <version>1.0.0</version>
    </parent>

    <artifactId>api-gateway</artifactId>
    <version>1.0.0</version>
    <name>API Gateway</name>
    <description>API Gateway for microservices</description>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-gateway</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
        <finalName>app</finalName>
    </build>
</project>
```

### 2. `api-gateway/Dockerfile`

```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/app.jar app.jar
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 3. `api-gateway/src/main/resources/application.yml`

```yaml
spring:
  application:
    name: api-gateway
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}

---
spring:
  config:
    activate:
      on-profile: dev
  cloud:
    gateway:
      routes:
        - id: product-service
          uri: http://localhost:8081
          predicates:
            - Path=/api/products/**
          filters:
            - DedupeResponseHeader=Access-Control-Allow-Credentials Access-Control-Allow-Origin

        - id: order-service
          uri: http://localhost:8082
          predicates:
            - Path=/api/orders/**
          filters:
            - DedupeResponseHeader=Access-Control-Allow-Credentials Access-Control-Allow-Origin

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health,info,gateway,prometheus
  endpoint:
    health:
      probes:
        enabled: true
      show-details: always
    gateway:
      enabled: true

---
spring:
  config:
    activate:
      on-profile: kubernetes
  cloud:
    gateway:
      routes:
        - id: product-service
          uri: ${PRODUCT_SERVICE_URL:http://product-service:8081}
          predicates:
            - Path=/api/products/**
          filters:
            - DedupeResponseHeader=Access-Control-Allow-Credentials Access-Control-Allow-Origin

        - id: order-service
          uri: ${ORDER_SERVICE_URL:http://order-service:8082}
          predicates:
            - Path=/api/orders/**
          filters:
            - DedupeResponseHeader=Access-Control-Allow-Credentials Access-Control-Allow-Origin

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health,info,gateway,prometheus
  endpoint:
    health:
      probes:
        enabled: true
    gateway:
      enabled: true
```

### 4. `api-gateway/src/main/java/com/ecommerce/gateway/ApiGatewayApplication.java`

```java
package com.ecommerce.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ApiGatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.java, args);
    }
}
```

---

## Additional Files

### `.gitignore`

```
target/
!.mvn/wrapper/maven-wrapper.jar
!**/src/main/**/target/
!**/src/test/**/target/

### STS ###
.apt_generated
.classpath
.factorypath
.project
.settings
.springBeans
.sts4-cache

### IntelliJ IDEA ###
.idea
*.iws
*.iml
*.ipr

### NetBeans ###
/nbproject/private/
/nbbuild/
/dist/
/nbdist/
/.nb-gradle/
build/
!**/src/main/**/build/
!**/src/test/**/build/

### VS Code ###
.vscode/

### GCP ###
key.json
*.json

### OS ###
.DS_Store
```

### `docker-compose.yml` (for local testing)

```yaml
version: '3.8'

services:
  product-service:
    build: ./product-service
    ports:
      - "8081:8081"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
    networks:
      - ecommerce-network

  order-service:
    build: ./order-service
    ports:
      - "8082:8082"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - PRODUCT_SERVICE_URL=http://product-service:8081
    depends_on:
      - product-service
    networks:
      - ecommerce-network

  api-gateway:
    build: ./api-gateway
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - PRODUCT_SERVICE_URL=http://product-service:8081
      - ORDER_SERVICE_URL=http://order-service:8082
    depends_on:
      - product-service
      - order-service
    networks:
      - ecommerce-network

networks:
  ecommerce-network:
    driver: bridge
```

---

## Quick Setup Commands

```bash
# 1. Create all source directories
./CREATE_COMPLETE_PROJECT.sh

# 2. Copy all code files into their respective directories

# 3. Build the project
mvn clean package

# 4. Test locally with Docker Compose
docker-compose up --build

# 5. Test endpoints
curl http://localhost:8080/api/products
curl http://localhost:8080/actuator/health
```

---

For complete working code, refer to the template repository structure.
