package com.restaurant.customer

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.http.{HeaderNames, HeaderValues}

import scala.concurrent.duration.DurationLong

class NightCustomer extends Simulation {

  val httpProtocol = http
    .baseUrl("http://34.117.101.246")
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
        .get("/enter")
        .check(status.is(200))
        .check(bodyString.is("Entered"))
    )
    .pause(4.seconds, 6.seconds)
    .exec(
      http("Order")
        .get("/order")
        .check(status.is(200))
        .check(bodyString.is("Ordered"))
    )
    .pause(45.seconds, 60.seconds)
    .exec(
      http("Pay")
        .get("/pay")
        .check(status.is(200))
        .check(bodyString.is("Payed"))
    )

    setUp(
      customers.inject(
        nothingFor(3.seconds),
        // fisrt wave
        rampUsers(50).during(3.seconds),
        rampUsers(50).during(4.seconds),
        rampUsers(50).during(7.seconds),
        nothingFor(45.seconds),
        // second wave
        rampUsers(15).during(3.seconds),
        rampUsers(15).during(4.seconds),
        rampUsers(15).during(7.seconds),
      )
    ).protocols(httpProtocol)
}
