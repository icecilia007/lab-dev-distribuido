package com.logistica.rastreamento.repository;

import com.logistica.rastreamento.model.Localizacao;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface LocalizacaoRepository extends JpaRepository<Localizacao, Long> {

    Optional<Localizacao> findTopByPedidoIdOrderByTimestampDesc(Long pedidoId);

    List<Localizacao> findByPedidoIdOrderByTimestampDesc(Long pedidoId);

    @Query(value = "SELECT * FROM localizacoes l " +
            "WHERE l.id IN (SELECT MAX(id) FROM localizacoes GROUP BY pedido_id) " +
            "AND (6371 * acos(cos(radians(?1)) * cos(radians(l.latitude)) * " +
            "cos(radians(l.longitude) - radians(?2)) + sin(radians(?1)) * " +
            "sin(radians(l.latitude)))) < ?3", nativeQuery = true)
    List<Localizacao> encontrarEntregasProximas(Double latitude, Double longitude, Double raioKm);


    List<Localizacao> findByMotoristaIdAndTimestampBetweenOrderByTimestamp(
            Long motoristaId, LocalDateTime inicio, LocalDateTime fim);

    Optional<Localizacao> findTopByMotoristaIdOrderByTimestampDesc(Long motoristaId);

    /*    @Query(value =
                "WITH ultimas_localizacoes AS (" +
                        "   SELECT DISTINCT ON (motorista_id) * " +
                        "   FROM localizacoes " +
                        "   ORDER BY motorista_id, timestamp DESC" +
                        ") " +
                        "SELECT l.*, " +
                        "   (6371 * acos(cos(radians(?1)) * cos(radians(l.latitude)) * " +
                        "   cos(radians(l.longitude) - radians(?2)) + sin(radians(?1)) * " +
                        "   sin(radians(l.latitude)))) AS distancia " +
                        "FROM ultimas_localizacoes l " +
                        "WHERE l.status_veiculo = 'DISPONIVEL' " +
                        "AND (6371 * acos(cos(radians(?1)) * cos(radians(l.latitude)) * " +
                        "   cos(radians(l.longitude) - radians(?2)) + sin(radians(?1)) * " +
                        "   sin(radians(l.latitude)))) < ?3 " +
                        "ORDER BY distancia",
                nativeQuery = true)
        List<Object[]> encontrarMotoristasProximos(Double latitude, Double longitude, Double raioKm);*/
    @Query(value =
            "WITH ultimas_localizacoes AS (" +
                    "   SELECT DISTINCT ON (motorista_id) * " +
                    "   FROM localizacoes " +
                    "   ORDER BY motorista_id, timestamp DESC" +
                    ") " +
                    "SELECT l.motorista_id, l.latitude, l.longitude, l.timestamp," +
                    "   (6371 * acos(cos(radians(?1)) * cos(radians(l.latitude)) * " +
                    "   cos(radians(l.longitude) - radians(?2)) + sin(radians(?1)) * " +
                    "   sin(radians(l.latitude)))) AS distancia " +
                    "FROM ultimas_localizacoes l " +
                    "WHERE l.status_veiculo = 'DISPONIVEL' " +
                    "AND (6371 * acos(cos(radians(?1)) * cos(radians(l.latitude)) * " +
                    "   cos(radians(l.longitude) - radians(?2)) + sin(radians(?1)) * " +
                    "   sin(radians(l.latitude)))) < ?3 " +
                    "ORDER BY distancia",
            nativeQuery = true)
    List<Object[]> encontrarMotoristasProximos(Double latitude, Double longitude, Double raioKm);

}


