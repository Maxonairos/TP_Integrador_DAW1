package ar.edu.undec.tp_integrador_daw1.service;

import ar.edu.undec.tp_integrador_daw1.dto.ReservaFijaRequest;
import ar.edu.undec.tp_integrador_daw1.dto.ReservaRequest;
import ar.edu.undec.tp_integrador_daw1.dto.ReservaResponse;
import ar.edu.undec.tp_integrador_daw1.entity.Cancha;
import ar.edu.undec.tp_integrador_daw1.entity.Cliente;
import ar.edu.undec.tp_integrador_daw1.entity.EstadoReserva;
import ar.edu.undec.tp_integrador_daw1.entity.Reserva;
import ar.edu.undec.tp_integrador_daw1.exception.ConflictoException;
import ar.edu.undec.tp_integrador_daw1.exception.RecursoNoEncontradoException;
import ar.edu.undec.tp_integrador_daw1.repository.CanchaRepository;
import ar.edu.undec.tp_integrador_daw1.repository.ClienteRepository;
import ar.edu.undec.tp_integrador_daw1.repository.ReservaRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class ReservaService {

    private static final BigDecimal RECARGO = new BigDecimal("0.50");
    private static final BigDecimal TARIFA_NOCTURNA = new BigDecimal("1.20");

    private static final Map<EstadoReserva, Set<EstadoReserva>> TRANSICIONES =
            Map.of(
                    EstadoReserva.PENDIENTE,
                    EnumSet.of(EstadoReserva.CONFIRMADA, EstadoReserva.CANCELADA),
                    EstadoReserva.CONFIRMADA,
                    EnumSet.of(EstadoReserva.FINALIZADA, EstadoReserva.CANCELADA),
                    EstadoReserva.FINALIZADA,
                    EnumSet.noneOf(EstadoReserva.class),
                    EstadoReserva.CANCELADA,
                    EnumSet.noneOf(EstadoReserva.class));

    private final ReservaRepository reservaRepository;
    private final CanchaRepository canchaRepository;
    private final ClienteRepository clienteRepository;

    public ReservaService(
            ReservaRepository reservaRepository,
            CanchaRepository canchaRepository,
            ClienteRepository clienteRepository) {
        this.reservaRepository = reservaRepository;
        this.canchaRepository = canchaRepository;
        this.clienteRepository = clienteRepository;
    }

    public List<ReservaResponse> listar() {
        return reservaRepository.findAllByOrderByInicioAsc().stream()
                .map(ReservaResponse::desde)
                .toList();
    }

    public ReservaResponse obtener(Long id) {
        return ReservaResponse.desde(buscarEntidad(id));
    }

    @Transactional
    public ReservaResponse crear(ReservaRequest request) {
        Cancha cancha = buscarCancha(request.canchaId());
        Cliente cliente = buscarCliente(request.clienteId());
        verificarSuperposicion(request.canchaId(), request.inicio(), request.horas(), null);

        Reserva reserva = new Reserva();
        reserva.setCancha(cancha);
        reserva.setCliente(cliente);
        reserva.setInicio(request.inicio());
        reserva.setHoras(request.horas());
        reserva.setPrecioTotal(calcularPrecio(cancha, request.inicio(), request.horas()));
        reserva.setRecargo(BigDecimal.ZERO);
        reserva.setEstado(EstadoReserva.PENDIENTE);
        return ReservaResponse.desde(reservaRepository.save(reserva));
    }

    @Transactional
    public List<ReservaResponse> crearFijas(ReservaFijaRequest request) {
        Cancha cancha = buscarCancha(request.canchaId());
        Cliente cliente = buscarCliente(request.clienteId());

        List<LocalDateTime> inicios = new ArrayList<>();
        for (int semana = 0; semana < request.semanas(); semana++) {
            inicios.add(request.inicio().plusWeeks(semana));
        }

        // Se validan todas antes de guardar: si una se superpone, no se crea ninguna.
        for (LocalDateTime inicio : inicios) {
            verificarSuperposicion(request.canchaId(), inicio, request.horas(), null);
        }

        List<Reserva> nuevas = new ArrayList<>();
        for (LocalDateTime inicio : inicios) {
            Reserva reserva = new Reserva();
            reserva.setCancha(cancha);
            reserva.setCliente(cliente);
            reserva.setInicio(inicio);
            reserva.setHoras(request.horas());
            reserva.setPrecioTotal(calcularPrecio(cancha, inicio, request.horas()));
            reserva.setRecargo(BigDecimal.ZERO);
            reserva.setEstado(EstadoReserva.PENDIENTE);
            nuevas.add(reserva);
        }

        return reservaRepository.saveAll(nuevas).stream()
                .map(ReservaResponse::desde)
                .toList();
    }

    @Transactional
    public ReservaResponse actualizar(Long id, ReservaRequest request) {
        Reserva reserva = buscarEntidad(id);
        if (reserva.getEstado() == EstadoReserva.CANCELADA
                || reserva.getEstado() == EstadoReserva.FINALIZADA) {
            throw new ConflictoException(
                    "No se puede modificar una reserva " + reserva.getEstado());
        }
        Cancha cancha = buscarCancha(request.canchaId());
        Cliente cliente = buscarCliente(request.clienteId());
        verificarSuperposicion(request.canchaId(), request.inicio(), request.horas(), id);

        reserva.setCancha(cancha);
        reserva.setCliente(cliente);
        reserva.setInicio(request.inicio());
        reserva.setHoras(request.horas());
        reserva.setPrecioTotal(calcularPrecio(cancha, request.inicio(), request.horas()));
        reserva.setRecargo(BigDecimal.ZERO);
        return ReservaResponse.desde(reservaRepository.save(reserva));
    }

    @Transactional
    public ReservaResponse cambiarEstado(Long id, EstadoReserva nuevoEstado) {
        Reserva reserva = buscarEntidad(id);
        Set<EstadoReserva> permitidos = TRANSICIONES.get(reserva.getEstado());
        if (permitidos == null || !permitidos.contains(nuevoEstado)) {
            throw new ConflictoException(
                    "No se puede pasar de "
                            + reserva.getEstado()
                            + " a "
                            + nuevoEstado);
        }
        reserva.setEstado(nuevoEstado);
        if (nuevoEstado == EstadoReserva.CANCELADA) {
            reserva.setRecargo(calcularRecargo(reserva));
        }
        return ReservaResponse.desde(reservaRepository.save(reserva));
    }

    @Transactional
    public void eliminar(Long id) {
        reservaRepository.delete(buscarEntidad(id));
    }

    private Reserva buscarEntidad(Long id) {
        return reservaRepository
                .findById(id)
                .orElseThrow(
                        () -> new RecursoNoEncontradoException("No existe la reserva " + id));
    }

    private Cancha buscarCancha(Long id) {
        return canchaRepository
                .findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe la cancha " + id));
    }

    private Cliente buscarCliente(Long id) {
        return clienteRepository
                .findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe el cliente " + id));
    }

    private void verificarSuperposicion(
            Long canchaId, LocalDateTime inicio, Integer horas, Long reservaExcluidaId) {
        LocalDateTime fin = inicio.plusHours(horas);
        boolean seSuperpone =
                reservaRepository.findByCanchaIdAndEstadoNot(canchaId, EstadoReserva.CANCELADA)
                        .stream()
                        .filter(r -> !r.getId().equals(reservaExcluidaId))
                        .anyMatch(
                                r ->
                                        inicio.isBefore(r.getFin())
                                                && fin.isAfter(r.getInicio()));
        if (seSuperpone) {
            throw new ConflictoException(
                    "La cancha ya tiene una reserva que se superpone con ese horario");
        }
    }

    private BigDecimal calcularPrecio(Cancha cancha, LocalDateTime inicio, Integer horas) {
        BigDecimal total = BigDecimal.ZERO;
        for (int hora = 0; hora < horas; hora++) {
            BigDecimal precioHora = cancha.getPrecioHora();
            if (inicio.plusHours(hora).getHour() >= 20) {
                precioHora = precioHora.multiply(TARIFA_NOCTURNA);
            }
            total = total.add(precioHora);
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Cancelar con menos de 24 h de anticipación deja un recargo del 50 % del precio total.
     */
    private BigDecimal calcularRecargo(Reserva reserva) {
        LocalDateTime limite = reserva.getInicio().minusHours(24);
        if (LocalDateTime.now().isAfter(limite)) {
            return reserva
                    .getPrecioTotal()
                    .multiply(RECARGO)
                    .setScale(2, RoundingMode.HALF_UP);
        }
        return BigDecimal.ZERO;
    }
}
