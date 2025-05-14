package com.logistica.usuario.repository;

import com.logistica.usuario.dto.UsuarioResponse;
import com.logistica.usuario.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

// Repositório base
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    Optional<Usuario> findByEmail(String email);

    @Query("SELECT new com.logistica.usuario.dto.UsuarioResponse(u.id, u.nome, u.email, cast(TYPE(u) as string), u.telefone) " +
            "FROM Usuario u WHERE u.email = :email AND u.senha = :senha")
    Optional<UsuarioResponse> findProjectedByEmailAndSenha(@Param("email") String email,@Param("senha") String senha);
}





