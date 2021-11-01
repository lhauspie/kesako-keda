package com.restaurant.customer

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.http.{HeaderNames, HeaderValues}

import scala.concurrent.duration.DurationLong

class NoonCustomer extends Simulation {

  val timeDivisor = 15;
//  val enter_host = "restaurant-staff-enter";
//  val order_host = "restaurant-staff-order";
//  val pay_host = "restaurant-staff-pay";
  val enter_host = "34.117.101.246";
  val order_host = "34.117.101.246";
  val pay_host = "34.117.101.246";

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

  val customers = scenario("Eat to Office Restaurant")
    .pause(5.minutes / timeDivisor, 10.minutes / timeDivisor)
    .exec(
      http("Enter")
        .get(s"http://$enter_host/enter")
//        .requestTimeout(5.minutes / timeDivisor)
        .check(status.is(200))
        .check(bodyString.is("Entered"))
    )
    .pause(15.minutes / timeDivisor, 20.minutes / timeDivisor)
    .exec(
      http("Order")
        .get(s"http://$order_host/order")
//        .requestTimeout(10.minutes / timeDivisor)
        .check(status.is(200))
        .check(bodyString.is("Ordered"))
    )
    .pause(30.minutes / timeDivisor, 45.minutes / timeDivisor)
    .rendezVous(200)
    .pause(0.minutes / timeDivisor, 15.minutes / timeDivisor)
    .exec(
      http("Pay")
        .get(s"http://$pay_host/pay")
//        .requestTimeout(5.minutes / timeDivisor)
        .check(status.is(200))
        .check(bodyString.is("Payed"))
    )
    .exitHereIfFailed

    setUp(
      customers.inject(
        nothingFor(3.minutes / timeDivisor),
        rampUsers(50).during(3.minutes / timeDivisor),
        rampUsers(50).during(4.minutes / timeDivisor),
        rampUsers(50).during(7.minutes / timeDivisor),
        rampUsers(50).during(11.minutes / timeDivisor),
      )
    ).protocols(httpProtocol)
}
