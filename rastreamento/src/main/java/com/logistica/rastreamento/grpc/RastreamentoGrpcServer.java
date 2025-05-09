package com.logistica.rastreamento.grpc;

import com.logistica.rastreamento.dto.AtualizacaoLocalizacaoDTO;
import com.logistica.rastreamento.dto.LocalizacaoDTO;
import com.logistica.rastreamento.grpc.*;
import com.logistica.rastreamento.service.LocalizacaoObserver;
import com.logistica.rastreamento.service.RastreamentoService;
import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.concurrent.Executor;


import java.time.ZoneOffset;
import java.util.List;

@GrpcService
public class RastreamentoGrpcServer extends RastreamentoServiceGrpc.RastreamentoServiceImplBase {

    private final RastreamentoService rastreamentoService;
    Executor directExecutor = Runnable::run;


    @Autowired
    public RastreamentoGrpcServer(RastreamentoService rastreamentoService) {
        this.rastreamentoService = rastreamentoService;
    }

    @Override
    public void atualizarLocalizacao(AtualizacaoLocalizacaoRequest request,
                                     StreamObserver<AtualizacaoLocalizacaoResponse> responseObserver) {

        AtualizacaoLocalizacaoDTO dto = new AtualizacaoLocalizacaoDTO();
        dto.setPedidoId(request.getPedidoId());
        dto.setMotoristaId(request.getMotoristaId());
        dto.setLatitude(request.getLatitude());
        dto.setLongitude(request.getLongitude());
        dto.setStatusVeiculo(request.getStatusVeiculo());

        boolean sucesso = rastreamentoService.atualizarLocalizacao(dto);

        AtualizacaoLocalizacaoResponse response = AtualizacaoLocalizacaoResponse.newBuilder()
                .setSucesso(sucesso)
                .setMensagem(sucesso ? "Localização atualizada com sucesso" : "Erro ao atualizar localização")
                .build();

        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }

    @Override
    public void consultarLocalizacao(ConsultaLocalizacaoRequest request,
                                     StreamObserver<LocalizacaoResponse> responseObserver) {

        try {
            LocalizacaoDTO localizacao = rastreamentoService.consultarLocalizacaoAtual(request.getPedidoId());

            LocalizacaoResponse response = converterParaGrpc(localizacao);

            responseObserver.onNext(response);
            responseObserver.onCompleted();

        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }

    @Override
    public void monitorarLocalizacao(ConsultaLocalizacaoRequest request,
                                     StreamObserver<LocalizacaoResponse> responseObserver) {

        Long pedidoId = request.getPedidoId();

        // Enviar localização atual imediatamente
        try {
            LocalizacaoDTO localizacaoAtual = rastreamentoService.consultarLocalizacaoAtual(pedidoId);
            responseObserver.onNext(converterParaGrpc(localizacaoAtual));
        } catch (Exception e) {
            // Ignorar se não houver dados iniciais
        }

        // Registrar observador para atualizações futuras
        LocalizacaoObserver observer = new LocalizacaoObserver() {
            @Override
            public void onNovaLocalizacao(LocalizacaoDTO localizacao) {
                responseObserver.onNext(converterParaGrpc(localizacao));
            }
        };

        rastreamentoService.registrarObservador(pedidoId, observer);

        // Usar io.grpc.Context para detectar quando a conexão for fechada
        io.grpc.Context.current().addListener(
                context -> rastreamentoService.removerObservador(pedidoId, observer),
                io.grpc.Context.currentContextExecutor(directExecutor)
        );
    }

    @Override
    public void buscarEntregasProximas(BuscarProximasRequest request,
                                       StreamObserver<EntregasProximasResponse> responseObserver) {

        List<LocalizacaoDTO> entregasProximas = rastreamentoService.buscarEntregasProximas(
                request.getLatitude(),
                request.getLongitude(),
                request.getRaioKm()
        );

        EntregasProximasResponse.Builder responseBuilder = EntregasProximasResponse.newBuilder();

        for (LocalizacaoDTO localizacao : entregasProximas) {
            EntregaProxima entrega = EntregaProxima.newBuilder()
                    .setPedidoId(localizacao.getPedidoId())
                    .setLatitude(localizacao.getLatitude())
                    .setLongitude(localizacao.getLongitude())
                    .setDistanciaKm(localizacao.getDistanciaDestinoKm())
                    .build();

            responseBuilder.addEntregas(entrega);
        }

        responseObserver.onNext(responseBuilder.build());
        responseObserver.onCompleted();
    }

    private LocalizacaoResponse converterParaGrpc(LocalizacaoDTO dto) {
        return LocalizacaoResponse.newBuilder()
                .setPedidoId(dto.getPedidoId())
                .setLatitude(dto.getLatitude())
                .setLongitude(dto.getLongitude())
                .setTimestamp(dto.getTimestamp().toEpochSecond(ZoneOffset.UTC))
                .setStatusEntrega(dto.getStatusVeiculo())
                .setDistanciaDestinoKm(dto.getDistanciaDestinoKm())
                .setTempoEstimadoMinutos(dto.getTempoEstimadoMinutos())
                .build();
    }
}
