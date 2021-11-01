noon:
	mvn gatling:test -Dgatling.simulationClass=com.restaurant.customer.NoonCustomer

night:
	mvn gatling:test -Dgatling.simulationClass=com.restaurant.customer.NightCustomer

scaleup:
	mvn gatling:test -Dgatling.simulationClass=com.restaurant.customer.ScaleUp

fulfill:
	rm -f ./gatling.log
	mvn gatling:test -Dgatling.simulationClass=com.restaurant.customer.FulfillElastic