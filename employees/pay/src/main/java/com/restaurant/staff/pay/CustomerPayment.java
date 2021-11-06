package com.restaurant.staff.pay;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

import javax.persistence.Entity;
import java.time.LocalDateTime;

@Entity
public class CustomerPayment extends PanacheEntity {
    public LocalDateTime paymentTime;
}

