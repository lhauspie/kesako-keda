package com.restaurant.staff.pay;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class PayTest {

    @Test
    public void testPayEndpoint() {
        given()
          .when().get("/pay")
          .then()
             .statusCode(200)
             .body(is("Payed"));
    }
}