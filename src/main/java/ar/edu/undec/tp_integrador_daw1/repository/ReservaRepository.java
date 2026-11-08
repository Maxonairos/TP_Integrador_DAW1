package ar.edu.undec.tp_integrador_daw1.repository;

import ar.edu.undec.tp_integrador_daw1.entity.EstadoReserva;
import ar.edu.undec.tp_integrador_daw1.entity.Reserva;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReservaRepository extends JpaRepository<Reserva, Long> {

    List<Reserva> findAllByOrderByInicioAsc();

    List<Reserva> findByCanchaIdOrderByInicioAsc(Long canchaId);

    List<Reserva> findByCanchaIdAndInicioGreaterThanEqualAndInicioLessThanOrderByInicioAsc(
            Long canchaId, LocalDateTime desde, LocalDateTime hasta);

    List<Reserva> findByClienteIdOrderByInicioAsc(Long clienteId);

    List<Reserva> findByCanchaIdAndEstadoNot(Long canchaId, EstadoReserva estado);

    List<Reserva> findByEstadoAndInicioGreaterThanEqualAndInicioLessThanOrderByInicioAsc(
            EstadoReserva estado, LocalDateTime desde, LocalDateTime hasta);

    boolean existsByCanchaId(Long canchaId);

    boolean existsByClienteId(Long clienteId);
}
