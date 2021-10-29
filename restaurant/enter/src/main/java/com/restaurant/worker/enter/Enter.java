package com.restaurant.staff.enter;

import javax.ws.rs.GET;
import javax.ws.rs.Produces;
import javax.ws.rs.Path;
import javax.ws.rs.core.MediaType;

import io.quarkus.logging.Log;

@Path("/enter")
public class Enter {

    private String sync_string = "";
    private final Long time = 330L; // means 20 seconds in real life

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String enter() throws InterruptedException {
        synchronized (sync_string) {
            Log.infof("Entering during %d ms", time);
            Thread.sleep(time);
        }
        return "Entered";
    }
}