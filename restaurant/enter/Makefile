build:
	mvn package -Pnative -Dquarkus.native.container-build=true

package:
	docker build . -f src/main/docker/Dockerfile.native-distroless -t lhauspie/restaurant-staff-enter:1.0.0

deliver:
	docker push lhauspie/restaurant-staff-enter:1.0.0

all: build package deliver

