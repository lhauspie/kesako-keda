package com.restaurant.staff.enter;

import javax.transaction.Transactional;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import io.quarkus.logging.Log;

import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.time.Duration;
import java.time.LocalDateTime;

@Path("/enter")
@Transactional
public class Enter {

    @ConfigProperty(name = "time.divisor")
    private Long timeDivisor;

    private Duration enteringTime = Duration.ofSeconds(20);
    private String sync_string = "";

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String enter() throws InterruptedException {
        synchronized (sync_string) {
            CustomerArrival customerArrival = new CustomerArrival();
            customerArrival.arrivalTime = LocalDateTime.now();
            customerArrival.persist();
            long enteringTimeMillis = enteringTime.dividedBy(timeDivisor).toMillis();
            Log.infof("Entering during %d ms", enteringTimeMillis);
            Thread.sleep(enteringTimeMillis);
        }
        return "Entered";
    }
}