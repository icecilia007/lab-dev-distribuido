package com.logistica.rastreamento;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class RastreamentoApplication {

    public static void main(String[] args) {
        SpringApplication.run(RastreamentoApplication.class, args);
    }

}
