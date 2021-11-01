package com.restaurant.staff.enter;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class EnterTest {

    @Test
    public void testEnterEndpoint() {
        given()
          .when().get("/enter")
          .then()
             .statusCode(200)
             .body(is("Entered"));
    }
}