FROM anapsix/alpine-java
LABEL maintainer="devops@vibedesenv.com"
COPY APP_NAME /home/APP_NAME
CMD ["java","-Xmx128m","-jar","/home/APP_NAME"]
