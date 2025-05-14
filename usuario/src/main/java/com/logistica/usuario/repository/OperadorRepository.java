package com.logistica.usuario.repository;

import com.logistica.usuario.model.OperadorLogistico;
import org.springframework.data.jpa.repository.JpaRepository;

// Repositório de Operador
public interface OperadorRepository extends JpaRepository<OperadorLogistico, Long> {
}

