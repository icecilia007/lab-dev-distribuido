package com.logistica.usuario.controller;

import com.logistica.usuario.dto.LoginResquest;
import com.logistica.usuario.dto.UsuarioResponse;
import com.logistica.usuario.model.Cliente;
import com.logistica.usuario.model.Motorista;
import com.logistica.usuario.model.OperadorLogistico;
import com.logistica.usuario.model.Usuario;
import com.logistica.usuario.service.UsuarioService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/usuarios")
public class UsuarioController {
    private final UsuarioService usuarioService;

    public UsuarioController(UsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    @PostMapping ("/login")
    public ResponseEntity<UsuarioResponse> buscarClientePorId(@RequestBody LoginResquest usuario) {
        var usuarioResponse = usuarioService.login(usuario);

        return usuarioResponse.map(ResponseEntity::ok)
                .orElse(ResponseEntity.status(401).build());
    }
    // Endpoints para Cliente
    @PostMapping("/clientes")
    public ResponseEntity<UsuarioResponse> criarCliente(@RequestBody Cliente cliente) {
        var novoCliente = usuarioService.criarCliente(cliente);
        return new ResponseEntity<>(novoCliente, HttpStatus.CREATED);
    }

    @GetMapping("/clientes")
    public ResponseEntity<List<Cliente>> buscarTodosClientes() {
        List<Cliente> clientes = usuarioService.buscarTodosClientes();
        return ResponseEntity.ok(clientes);
    }

    @GetMapping("/clientes/{id}")
    public ResponseEntity<Cliente> buscarClientePorId(@PathVariable Long id) {
        Cliente cliente = usuarioService.buscarClientePorId(id);
        return ResponseEntity.ok(cliente);
    }

    @PutMapping("/clientes/{id}")
    public ResponseEntity<Cliente> atualizarCliente(@PathVariable Long id, @RequestBody Cliente cliente) {
        Cliente clienteAtualizado = usuarioService.atualizarCliente(id, cliente);
        return ResponseEntity.ok(clienteAtualizado);
    }

    @DeleteMapping("/clientes/{id}")
    public ResponseEntity<Void> deletarCliente(@PathVariable Long id) {
        usuarioService.deletarCliente(id);
        return ResponseEntity.noContent().build();
    }

    // Endpoints para Motoristas
    @PostMapping("/motoristas")
    public ResponseEntity<Motorista> criarMotorista(@RequestBody Motorista motorista) {
        Motorista novoMotorista = usuarioService.criarMotorista(motorista);
        return new ResponseEntity<>(novoMotorista, HttpStatus.CREATED);
    }

    @GetMapping("/motoristas")
    public ResponseEntity<List<Motorista>> buscarTodosMotoristas() {
        List<Motorista> motoristas = usuarioService.buscarTodosMotoristas();
        return ResponseEntity.ok(motoristas);
    }

    @GetMapping("/motoristas/{id}")
    public ResponseEntity<Motorista> buscarMotoristaPorId(@PathVariable Long id) {
        Motorista motorista = usuarioService.buscarMotoristaPorId(id);
        return ResponseEntity.ok(motorista);
    }

    @GetMapping("/motoristas/status/{status}")
    public ResponseEntity<List<Motorista>> buscarMotoristasPorStatus(@PathVariable String status) {
        List<Motorista> motoristas = usuarioService.buscarMotoristasPorStatus(status);
        return ResponseEntity.ok(motoristas);
    }

    @PutMapping("/motoristas/{id}")
    public ResponseEntity<Motorista> atualizarMotorista(@PathVariable Long id, @RequestBody Motorista motorista) {
        Motorista motoristaAtualizado = usuarioService.atualizarMotorista(id, motorista);
        return ResponseEntity.ok(motoristaAtualizado);
    }

    @DeleteMapping("/motoristas/{id}")
    public ResponseEntity<Void> deletarMotorista(@PathVariable Long id) {
        usuarioService.deletarMotorista(id);
        return ResponseEntity.noContent().build();
    }

    // Endpoints para Operadores Logísticos
    @PostMapping("/operadores")
    public ResponseEntity<OperadorLogistico> criarOperador(@RequestBody OperadorLogistico operador) {
        OperadorLogistico novoOperador = usuarioService.criarOperador(operador);
        return new ResponseEntity<>(novoOperador, HttpStatus.CREATED);
    }

    @GetMapping("/operadores")
    public ResponseEntity<List<OperadorLogistico>> buscarTodosOperadores() {
        List<OperadorLogistico> operadores = usuarioService.buscarTodosOperadores();
        return ResponseEntity.ok(operadores);
    }

    @GetMapping("/operadores/{id}")
    public ResponseEntity<OperadorLogistico> buscarOperadorPorId(@PathVariable Long id) {
        OperadorLogistico operador = usuarioService.buscarOperadorPorId(id);
        return ResponseEntity.ok(operador);
    }

    @PutMapping("/operadores/{id}")
    public ResponseEntity<OperadorLogistico> atualizarOperador(@PathVariable Long id, @RequestBody OperadorLogistico operador) {
        OperadorLogistico operadorAtualizado = usuarioService.atualizarOperador(id, operador);
        return ResponseEntity.ok(operadorAtualizado);
    }

    @DeleteMapping("/operadores/{id}")
    public ResponseEntity<Void> deletarOperador(@PathVariable Long id) {
        usuarioService.deletarOperador(id);
        return ResponseEntity.noContent().build();
    }
}

