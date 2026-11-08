package ar.edu.undec.tp_integrador_daw1.repository;

import ar.edu.undec.tp_integrador_daw1.entity.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClienteRepository extends JpaRepository<Cliente, Long> {
}
