FROM anapsix/alpine-java
LABEL maintainer="devops@vibedesenv.com"
COPY APP_NAME /home/cars-api-0.0.2-SNAPSHOT.jar
CMD ["java","-Xmx128m","-jar","/home/cars-api-0.0.2-SNAPSHOT.jar"]
