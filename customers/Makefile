noon:
	mvn gatling:test -Dgatling.simulationClass=com.restaurant.customer.NoonCustomer \
	 -Dhost=${RESTAURANT_IP} -Dtime_divisor=15

night:
	mvn gatling:test -Dgatling.simulationClass=com.restaurant.customer.NightCustomer \
	 -Dhost=${RESTAURANT_IP} -Dtime_divisor=15

package:
	docker build . -t lhauspie/restaurant-simulations:1.0.0

deliver:
	docker push lhauspie/restaurant-simulations:1.0.0
