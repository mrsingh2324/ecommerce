# Stage 1: Build
FROM maven:3.9.5-eclipse-temurin-17 AS build
WORKDIR /app

# Copy parent pom first
COPY ../pom.xml ./pom.xml

# Copy service pom
COPY pom.xml ./product-service/pom.xml

# Copy source
COPY src ./product-service/src

# Build the service
WORKDIR /app/product-service
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/product-service/target/app.jar app.jar
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]