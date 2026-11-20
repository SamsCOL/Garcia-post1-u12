# ── Etapa 1: compilacion con Maven ──────────────────────────────────
# Se usa la imagen oficial de Maven con JDK 21 (la imagen eclipse-temurin
# JDK por si sola NO incluye el comando `mvn`).
FROM maven:3.9-eclipse-temurin-21-alpine AS builder
WORKDIR /app

# Copiar pom.xml primero para aprovechar la cache de capas de Docker.
# Si las dependencias no cambian, Maven no las descarga en builds siguientes.
COPY pom.xml .
RUN mvn dependency:go-offline -q

COPY src ./src
RUN mvn clean package -DskipTests -q

# ── Etapa 2: imagen de ejecucion (solo JRE) ──────────────────────────
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Usuario no root: buena practica de seguridad en contenedores
RUN addgroup -S spring && adduser -S spring -G spring
USER spring

# Copiar unicamente el JAR compilado desde la etapa de builder
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
