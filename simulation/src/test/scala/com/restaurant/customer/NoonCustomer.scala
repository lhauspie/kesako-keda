package com.restaurant.customer

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.http.{HeaderNames, HeaderValues}

import scala.concurrent.duration.DurationLong

class NoonCustomer extends Simulation {

  val httpProtocol = http
    .baseUrl("http://localhost:8080")
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
    .pause(5.seconds, 10.seconds)
    .exec(
      http("Enter")
        .get("http://localhost:8081/enter")
        .check(status.is(200))
        .check(bodyString.is("Entered"))
    )
    .pause(4.seconds, 6.seconds)
    .exec(
      http("Order")
        .get("http://localhost:8082/order")
        .check(status.is(200))
        .check(bodyString.is("Ordered"))
    )
    .pause(30.seconds, 45.seconds)
    .rendezVous(200)
    .pause(0.seconds, 15.seconds)
    .exec(
      http("Pay")
        .get("http://localhost:8083/pay")
        .check(status.is(200))
        .check(bodyString.is("Payed"))
    )

    setUp(
      customers.inject(
        nothingFor(3.seconds),
        rampUsers(50).during(3.seconds),
        rampUsers(50).during(4.seconds),
        rampUsers(50).during(7.seconds),
        rampUsers(50).during(11.seconds),
      )
    ).protocols(httpProtocol)
}
