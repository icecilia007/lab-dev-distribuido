package com.logistica.usuario.repository;

import com.logistica.usuario.model.Motorista;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;


public interface MotoristaRepository extends JpaRepository<Motorista, Long> {
    List<Motorista> findByStatus(String status);
}
