package com.logistica.apigateway.controller.dto;

public record LoginRequest(
        String email,
        String password
){ }
