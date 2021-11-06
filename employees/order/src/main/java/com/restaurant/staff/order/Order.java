package com.restaurant.staff.order;

import javax.transaction.Transactional;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import io.quarkus.logging.Log;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import java.time.Duration;
import java.time.LocalDateTime;

@Path("/order")
@Transactional
public class Order {

    @ConfigProperty(name = "time.divisor")
    private Long timeDivisor;

    private Duration orderingTime = Duration.ofSeconds(30);
    private String sync_string = "";

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String order() throws InterruptedException {
        synchronized (sync_string) {
            CustomerOrdering customerOrdering = new CustomerOrdering();
            customerOrdering.orderingTime = LocalDateTime.now();
            customerOrdering.persist();
            long orderingTimeMillis = orderingTime.dividedBy(timeDivisor).toMillis();
            Log.infof("Ordering during %d ms", orderingTimeMillis);
            Thread.sleep(orderingTimeMillis);
        }
        return "Ordered";
    }
}