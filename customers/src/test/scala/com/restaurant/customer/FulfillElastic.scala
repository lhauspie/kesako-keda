package com.restaurant.customer

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.http.{HeaderNames, HeaderValues}

import scala.concurrent.duration.DurationLong

class FulfillElastic extends Simulation {

  val httpProtocol = http
    .baseUrl("https://c59a-93-16-127-73.ngrok.io")
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
        .post("/frequency/_doc")
        .basicAuth("elastic", "e00a7OGPmG04g60Z2c7AwU9u")
        .headers(headers)
        .body(StringBody("""
        {
          "event": "enter",
          "when": "${currentDate(yyyy-MM-dd'T'HH:mm:ss.SSS'Z')}"
        }
        """)).asJson
        .check(status.is(201))
    )
    .pause(4.seconds, 6.seconds)
    .exec(
      http("Order")
        .post("/frequency/_doc")
        .basicAuth("elastic", "e00a7OGPmG04g60Z2c7AwU9u")
        .headers(headers)
        .body(StringBody("""
        {
          "event": "order",
          "when": "${currentDate(yyyy-MM-dd'T'HH:mm:ss.SSS'Z')}"
        }
        """)).asJson
        .check(status.is(201))
    )
    .pause(30.seconds, 45.seconds)
    .rendezVous(200)
    .pause(0.seconds, 15.seconds)
    .exec(
      http("Pay")
        .post("/frequency/_doc")
        .basicAuth("elastic", "e00a7OGPmG04g60Z2c7AwU9u")
        .headers(headers)
        .body(StringBody("""
        {
          "event": "pay",
          "when": "${currentDate(yyyy-MM-dd'T'HH:mm:ss.SSS'Z')}"
        }
        """)).asJson
        .check(status.is(201))
    )

    setUp(
      customers.inject(
        rampUsers(50).during(3.seconds),
        rampUsers(50).during(4.seconds),
        rampUsers(50).during(7.seconds),
        rampUsers(50).during(11.seconds),
      )
    ).protocols(httpProtocol)
}
