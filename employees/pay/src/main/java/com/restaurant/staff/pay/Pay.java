package com.restaurant.staff.pay;

import javax.transaction.Transactional;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import io.quarkus.logging.Log;

import java.time.Duration;
import java.util.concurrent.ThreadLocalRandom;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import java.time.LocalDateTime;

@Path("/pay")
@Transactional
public class Pay {

    @ConfigProperty(name = "time.divisor")
    private Long timeDivisor;

    private Duration choosingTime = Duration.ofSeconds(15);
    private Duration payingTimeMin = Duration.ofSeconds(5);
    private Duration payingTimeMax = Duration.ofSeconds(13);
    private String sync_string = "";

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String pay() throws InterruptedException {
        synchronized (sync_string) {
            CustomerPayment customerPayment = new CustomerPayment();
            customerPayment.paymentTime = LocalDateTime.now();
            customerPayment.persist();

            boolean restartPayment = ThreadLocalRandom.current().nextInt(10) >= 8;
            long choosingTimeMillis = choosingTime.dividedBy(timeDivisor).toMillis();
            long payingTimeMinMillis = payingTimeMin.dividedBy(timeDivisor).toMillis();
            long payingTimeMaxMillis = payingTimeMax.dividedBy(timeDivisor).toMillis();
            Long timeToPayMillis = ThreadLocalRandom.current().nextLong(payingTimeMinMillis, payingTimeMaxMillis);
            Long waitingTime = choosingTimeMillis + timeToPayMillis;
            if (restartPayment) {
                waitingTime += timeToPayMillis;
            }
            Log.infof("Paying during %d ms", waitingTime);
            Thread.sleep(waitingTime);
        }
        return "Payed";
    }
}