package com.logistica.usuario.service;

import com.logistica.usuario.dto.LoginResquest;
import com.logistica.usuario.dto.UsuarioResponse;
import com.logistica.usuario.model.Cliente;
import com.logistica.usuario.model.Motorista;
import com.logistica.usuario.model.OperadorLogistico;
import com.logistica.usuario.model.Usuario;

import java.util.List;
import java.util.Optional;

public interface UsuarioService {
    Cliente criarCliente(Cliente cliente);

    List<Cliente> buscarTodosClientes();

    Cliente buscarClientePorId(Long id);

    Cliente atualizarCliente(Long id, Cliente cliente);

    void deletarCliente(Long id);

    Motorista criarMotorista(Motorista motorista);

    List<Motorista> buscarTodosMotoristas();

    Motorista buscarMotoristaPorId(Long id);

    List<Motorista> buscarMotoristasPorStatus(String status);

    Motorista atualizarMotorista(Long id, Motorista motorista);

    void deletarMotorista(Long id);

    OperadorLogistico criarOperador(OperadorLogistico operador);

    List<OperadorLogistico> buscarTodosOperadores();

    OperadorLogistico buscarOperadorPorId(Long id);

    OperadorLogistico atualizarOperador(Long id, OperadorLogistico operador);

    void deletarOperador(Long id);

    Optional<UsuarioResponse> login(LoginResquest usuario);
}
