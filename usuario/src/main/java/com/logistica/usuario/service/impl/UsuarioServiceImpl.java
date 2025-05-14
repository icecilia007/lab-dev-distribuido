package com.logistica.usuario.service.impl;

import com.logistica.usuario.dto.LoginResquest;
import com.logistica.usuario.dto.UsuarioResponse;
import com.logistica.usuario.exception.RecursoNaoEncontradoException;
import com.logistica.usuario.model.Cliente;
import com.logistica.usuario.model.Motorista;
import com.logistica.usuario.model.OperadorLogistico;
import com.logistica.usuario.model.Usuario;
import com.logistica.usuario.repository.ClienteRepository;
import com.logistica.usuario.repository.MotoristaRepository;
import com.logistica.usuario.repository.OperadorRepository;
import com.logistica.usuario.repository.UsuarioRepository;
import com.logistica.usuario.service.UsuarioService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UsuarioServiceImpl implements UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final ClienteRepository clienteRepository;
    private final MotoristaRepository motoristaRepository;
    private final OperadorRepository operadorRepository;

    // Injeção de dependências via construtor
    public UsuarioServiceImpl(UsuarioRepository usuarioRepository,
                          ClienteRepository clienteRepository,
                          MotoristaRepository motoristaRepository,
                          OperadorRepository operadorRepository) {
        this.usuarioRepository = usuarioRepository;
        this.clienteRepository = clienteRepository;
        this.motoristaRepository = motoristaRepository;
        this.operadorRepository = operadorRepository;
    }

    // Métodos para Cliente
    private UsuarioResponse converterParaUsuarioResponse(Usuario usuario) {
        String tipo = "";
        if (usuario instanceof Cliente) {
            tipo = "CLIENTE";
        } else if (usuario instanceof Motorista) {
            tipo = "MOTORISTA";
        } else if (usuario instanceof OperadorLogistico) {
            tipo = "OPERADOR";
        }

        return new UsuarioResponse(
                usuario.getId(),
                usuario.getNome(),
                usuario.getEmail(),
                tipo,
                usuario.getTelefone()
        );
    }

    public UsuarioResponse criarCliente(Cliente cliente) {
        Cliente clienteSalvo = clienteRepository.save(cliente);
        return converterParaUsuarioResponse(clienteSalvo);
    }


    public Cliente atualizarCliente(Long id, Cliente clienteDetalhes) {
        Cliente cliente = clienteRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Cliente não encontrado"));

        cliente.setNome(clienteDetalhes.getNome());
        cliente.setEmail(clienteDetalhes.getEmail());
        cliente.setSenha(clienteDetalhes.getSenha());

        return clienteRepository.save(cliente);
    }

    public Cliente buscarClientePorId(Long id) {
        return clienteRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Cliente não encontrado"));
    }

    public List<Cliente> buscarTodosClientes() {
        return clienteRepository.findAll();
    }

    public void deletarCliente(Long id) {
        Cliente cliente = clienteRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Cliente não encontrado"));
        clienteRepository.delete(cliente);
    }

    // Métodos para Motorista
    public UsuarioResponse criarMotorista(Motorista motorista) {
        motorista.setStatus("PARADO");
        Motorista motoristaSalvo = motoristaRepository.save(motorista);
        return converterParaUsuarioResponse(motoristaSalvo);
    }

    public Motorista atualizarMotorista(Long id, Motorista motoristaDetalhes) {
        Motorista motorista = motoristaRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Motorista não encontrado"));

        motorista.setNome(motoristaDetalhes.getNome());
        motorista.setEmail(motoristaDetalhes.getEmail());
        motorista.setSenha(motoristaDetalhes.getSenha());
        motorista.setPlaca(motoristaDetalhes.getPlaca());
        motorista.setModeloVeiculo(motoristaDetalhes.getModeloVeiculo());
        motorista.setAnoVeiculo(motoristaDetalhes.getAnoVeiculo());
        motorista.setConsumoMedioPorKm(motoristaDetalhes.getConsumoMedioPorKm());
        motorista.setStatus(motoristaDetalhes.getStatus());

        return motoristaRepository.save(motorista);
    }

    public Motorista buscarMotoristaPorId(Long id) {
        return motoristaRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Motorista não encontrado"));
    }

    public List<Motorista> buscarTodosMotoristas() {
        return motoristaRepository.findAll();
    }

    public List<Motorista> buscarMotoristasPorStatus(String status) {
        return motoristaRepository.findByStatus(status);
    }

    public void deletarMotorista(Long id) {
        Motorista motorista = motoristaRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Motorista não encontrado"));
        motoristaRepository.delete(motorista);
    }

    // Métodos para OperadorLogistico
    public UsuarioResponse criarOperador(OperadorLogistico operador) {
        OperadorLogistico operadorSalvo = operadorRepository.save(operador);
        return converterParaUsuarioResponse(operadorSalvo);
    }

    public OperadorLogistico atualizarOperador(Long id, OperadorLogistico operadorDetalhes) {
        OperadorLogistico operador = operadorRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Operador logístico não encontrado"));

        operador.setNome(operadorDetalhes.getNome());
        operador.setEmail(operadorDetalhes.getEmail());
        operador.setSenha(operadorDetalhes.getSenha());

        return operadorRepository.save(operador);
    }

    public OperadorLogistico buscarOperadorPorId(Long id) {
        return operadorRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Operador logístico não encontrado"));
    }

    public List<OperadorLogistico> buscarTodosOperadores() {
        return operadorRepository.findAll();
    }

    public void deletarOperador(Long id) {
        OperadorLogistico operador = operadorRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Operador logístico não encontrado"));
        operadorRepository.delete(operador);
    }

    @Override
    public Optional<UsuarioResponse> login(LoginResquest usuario) {
        Optional<UsuarioResponse> usr = usuarioRepository.findProjectedByEmailAndSenha(usuario.email(), usuario.password());
        return usr;
    }
}