FROM maven:3.8.3-openjdk-17

WORKDIR /gatling

COPY pom.xml pom.xml
COPY Makefile Makefile
COPY src/ src/

ENTRYPOINT ["mvn", "gatling:test"]