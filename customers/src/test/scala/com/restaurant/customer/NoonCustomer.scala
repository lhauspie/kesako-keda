package com.restaurant.customer

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.http.{HeaderNames, HeaderValues}

import scala.concurrent.duration.DurationLong

class NoonCustomer extends Simulation {
  // To run this test, please type this type of command:
  // $ mvn gatling:test -Dgatling.simulationClass=com.restaurant.customer.NoonCustomer -Dhost=34.117.101.245 -Dtime_divisor=15

  val timeDivisor = Integer.getInteger("time_divisor", 60).toInt
  val enter_host = System.getProperty("host", "restaurant-staff-enter:8080")
  val order_host = System.getProperty("host", "restaurant-staff-order:8080")
  val pay_host = System.getProperty("host", "restaurant-staff-pay:8080")

  val httpProtocol = http
    .inferHtmlResources(BlackList(""".*\.css""", """.*\.ico""", """.*\.js"""), WhiteList())
    .acceptHeader("*/*")
    .acceptEncodingHeader("gzip, deflate, br")
    .userAgentHeader("PostmanRuntime/7.26.8")
    .shareConnections

  val headers = Map(
    "Cache-Control" -> "no-cache",
    "Content-Type" -> "application/json"
  )

  val customers = scenario("Eat to Restaurant")
    .pause(0.minutes / timeDivisor, 5.minutes / timeDivisor)
    .exec(
      http("Enter")
        .get(s"http://$enter_host/enter")
        .check(status.is(200))
        .check(bodyString.is("Entered"))
    )
    .pause(15.minutes / timeDivisor, 20.minutes / timeDivisor)
    .exec(
      http("Order")
        .get(s"http://$order_host/order")
        .check(status.is(200))
        .check(bodyString.is("Ordered"))
    )
    .pause(30.minutes / timeDivisor, 45.minutes / timeDivisor)
    .rendezVous(200) // rendezVous is here to concentrate payment in 13h40 / 13h55
    .pause(0.minutes / timeDivisor, 15.minutes / timeDivisor)
    .exec(
      http("Pay")
        .get(s"http://$pay_host/pay")
        .check(status.is(200))
        .check(bodyString.is("Payed"))
    )

    setUp(
      customers.inject(
        rampUsers(50).during(3.minutes / timeDivisor),
        rampUsers(50).during(4.minutes / timeDivisor),
        rampUsers(50).during(7.minutes / timeDivisor),
        rampUsers(50).during(11.minutes / timeDivisor),
      )
    ).protocols(httpProtocol)
}
