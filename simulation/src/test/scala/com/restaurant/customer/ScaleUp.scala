package com.restaurant.customer

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.http.{HeaderNames, HeaderValues}

import scala.concurrent.duration.DurationLong

class ScaleUp extends Simulation {

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

  val customers = scenario("Go to Office Restaurant")
    .pause(0.seconds, 5.seconds)
    .exec(
      http("Pay")
        .get("/pay")
        .check(status.is(200))
        .check(bodyString.is("Payed"))
    )

    setUp(
      customers.inject(
        nothingFor(3.seconds),
        constantUsersPerSec(10).during(100.seconds),
      )
    ).protocols(httpProtocol)
}
