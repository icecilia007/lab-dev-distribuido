package com.logistica.usuario.repository;

import com.logistica.usuario.model.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;

// Repositório de Cliente
public interface ClienteRepository extends JpaRepository<Cliente, Long> {
}

