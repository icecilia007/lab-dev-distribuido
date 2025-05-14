package com.logistica.rastreamento.repository;

import com.logistica.rastreamento.model.Incidente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface IncidenteRepository extends JpaRepository<Incidente, Long> {

    List<Incidente> findByAtivoTrueAndDataExpiracaoAfter(LocalDateTime agora);

    @Query(value = "SELECT * FROM incidentes i " +
            "WHERE i.ativo = true " +
            "AND i.data_expiracao > ?1 " +
            "AND (6371 * acos(cos(radians(?2)) * cos(radians(i.latitude)) * " +
            "cos(radians(i.longitude) - radians(?3)) + sin(radians(?2)) * " +
            "sin(radians(i.latitude)))) < ?4", nativeQuery = true)
    List<Incidente> findIncidentesProximos(LocalDateTime agora, Double latitude, Double longitude, Double raioKm);


    @Modifying
    @Transactional
    @Query("UPDATE Incidente i SET i.ativo = false WHERE i.ativo = true AND i.dataExpiracao < :agora")
    int desativarIncidentesExpirados(LocalDateTime agora);
}
