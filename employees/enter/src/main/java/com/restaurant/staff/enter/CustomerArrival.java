package com.restaurant.staff.enter;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

import javax.persistence.Entity;
import java.time.LocalDateTime;

@Entity
public class CustomerArrival extends PanacheEntity {
    public LocalDateTime arrivalTime;
}

