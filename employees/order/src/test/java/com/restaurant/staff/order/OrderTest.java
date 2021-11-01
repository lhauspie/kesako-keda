package com.restaurant.staff.order;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class OrderTest {

    @Test
    public void testOrderEndpoint() {
        given()
          .when().get("/order")
          .then()
             .statusCode(200)
             .body(is("Ordered"));
    }
}