package com.restaurant.staff.order;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

import javax.persistence.Entity;
import java.time.LocalDateTime;

@Entity
public class CustomerOrdering extends PanacheEntity {
    public LocalDateTime orderingTime;
}

