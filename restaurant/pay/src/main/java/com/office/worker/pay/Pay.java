package com.restaurant.staff.pay;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import io.quarkus.logging.Log;
import java.util.concurrent.ThreadLocalRandom;

@Path("/pay")
public class Pay {

    private String sync_string = "";

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String pay() throws InterruptedException {
        synchronized (sync_string) {
            boolean restartPaiement = ThreadLocalRandom.current().nextInt(10) >= 8;
            Long timeToSelectDish = 330L; // means 20 seconds in real life
            Long timeToPay = ThreadLocalRandom.current().nextLong(250L); // means 15 seconds in real life
            Long time = timeToSelectDish + timeToPay;
            if (restartPaiement) {
                time += timeToPay;
            }
            Log.infof("Paying during %d ms", time);
            Thread.sleep(time);
        }
        return "Payed";
    }
}