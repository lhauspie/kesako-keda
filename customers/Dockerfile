FROM maven:3.8.3-openjdk-17

WORKDIR /gatling

COPY src/ src/
COPY Makefile Makefile
COPY pom.xml pom.xml

ENTRYPOINT ["mvn"]