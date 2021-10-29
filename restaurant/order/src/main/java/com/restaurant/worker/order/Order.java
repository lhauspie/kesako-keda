package com.restaurant.staff.order;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import io.quarkus.logging.Log;

@Path("/order")
public class Order {

    private String sync_string = "";
    private final Long time = 1000L; // means 1 minute in real life

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String order() throws InterruptedException {
        synchronized (sync_string) {
            Log.infof("Ordering during %d ms", time);
            Thread.sleep(time);
        }
        return "Ordered";
    }
}