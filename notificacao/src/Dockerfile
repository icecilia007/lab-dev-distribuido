FROM eclipse-temurin:21-jdk-alpine
WORKDIR /app
COPY target/notificacao-service.jar app.jar
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "app.jar"]
