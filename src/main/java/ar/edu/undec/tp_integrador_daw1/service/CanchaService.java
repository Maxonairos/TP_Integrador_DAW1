package ar.edu.undec.tp_integrador_daw1.service;

import ar.edu.undec.tp_integrador_daw1.dto.CanchaRequest;
import ar.edu.undec.tp_integrador_daw1.dto.CanchaResponse;
import ar.edu.undec.tp_integrador_daw1.dto.RecaudacionResponse;
import ar.edu.undec.tp_integrador_daw1.dto.ReservaResponse;
import ar.edu.undec.tp_integrador_daw1.entity.Cancha;
import ar.edu.undec.tp_integrador_daw1.entity.EstadoReserva;
import ar.edu.undec.tp_integrador_daw1.entity.Reserva;
import ar.edu.undec.tp_integrador_daw1.exception.ConflictoException;
import ar.edu.undec.tp_integrador_daw1.exception.RecursoNoEncontradoException;
import ar.edu.undec.tp_integrador_daw1.exception.SolicitudInvalidaException;
import ar.edu.undec.tp_integrador_daw1.repository.CanchaRepository;
import ar.edu.undec.tp_integrador_daw1.repository.ReservaRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class CanchaService {

    private final CanchaRepository canchaRepository;
    private final ReservaRepository reservaRepository;

    public CanchaService(CanchaRepository canchaRepository, ReservaRepository reservaRepository) {
        this.canchaRepository = canchaRepository;
        this.reservaRepository = reservaRepository;
    }

    public List<CanchaResponse> listar() {
        return canchaRepository.findAll().stream().map(CanchaResponse::desde).toList();
    }

    public CanchaResponse obtener(Long id) {
        return CanchaResponse.desde(buscarEntidad(id));
    }

    @Transactional
    public CanchaResponse crear(CanchaRequest request) {
        Cancha cancha = new Cancha();
        copiarDatos(cancha, request);
        return CanchaResponse.desde(canchaRepository.save(cancha));
    }

    @Transactional
    public CanchaResponse actualizar(Long id, CanchaRequest request) {
        Cancha cancha = buscarEntidad(id);
        copiarDatos(cancha, request);
        return CanchaResponse.desde(canchaRepository.save(cancha));
    }

    @Transactional
    public void eliminar(Long id) {
        Cancha cancha = buscarEntidad(id);
        if (reservaRepository.existsByCanchaId(id)) {
            throw new ConflictoException(
                    "No se puede borrar la cancha porque tiene reservas asociadas");
        }
        canchaRepository.delete(cancha);
    }

    public List<ReservaResponse> reservas(Long canchaId, LocalDate fecha) {
        buscarEntidad(canchaId);
        var reservas =
                fecha == null
                        ? reservaRepository.findByCanchaIdOrderByInicioAsc(canchaId)
                        : reservaRepository
                                .findByCanchaIdAndInicioGreaterThanEqualAndInicioLessThanOrderByInicioAsc(
                                        canchaId,
                                        fecha.atStartOfDay(),
                                        fecha.plusDays(1).atStartOfDay());
        return reservas.stream().map(ReservaResponse::desde).toList();
    }

    /**
     * Franjas de una hora que empiezan entre las 08:00 y las 22:00 (la última termina a las
     * 23:00) y no se superponen con ninguna reserva no cancelada de la cancha.
     */
    public List<String> disponibilidad(Long canchaId, LocalDate fecha) {
        buscarEntidad(canchaId);
        LocalDate dia = fecha == null ? LocalDate.now() : fecha;
        LocalDateTime inicioDia = dia.atStartOfDay();

        List<Reserva> activas =
                reservaRepository.findByCanchaIdAndEstadoNot(canchaId, EstadoReserva.CANCELADA);

        List<String> libres = new ArrayList<>();
        for (int hora = 8; hora <= 22; hora++) {
            LocalDateTime franjaInicio = inicioDia.plusHours(hora);
            LocalDateTime franjaFin = franjaInicio.plusHours(1);
            boolean ocupada =
                    activas.stream()
                            .anyMatch(
                                    r ->
                                            franjaInicio.isBefore(r.getFin())
                                                    && franjaFin.isAfter(r.getInicio()));
            if (!ocupada) {
                libres.add(String.format("%02d:00", hora));
            }
        }
        return libres;
    }

    /**
     * Total facturado por cancha con reservas FINALIZADAS en el mes indicado (AAAA-MM). Si no
     * se indica mes, se usa el mes actual.
     */
    public List<RecaudacionResponse> recaudacion(String mes) {
        YearMonth periodo;
        try {
            periodo = mes == null || mes.isBlank() ? YearMonth.now() : YearMonth.parse(mes);
        } catch (DateTimeParseException ex) {
            throw new SolicitudInvalidaException("El mes debe tener el formato AAAA-MM");
        }

        LocalDateTime desde = periodo.atDay(1).atStartOfDay();
        LocalDateTime hasta = periodo.plusMonths(1).atDay(1).atStartOfDay();
        List<Reserva> finalizadas =
                reservaRepository
                        .findByEstadoAndInicioGreaterThanEqualAndInicioLessThanOrderByInicioAsc(
                                EstadoReserva.FINALIZADA, desde, hasta);

        Map<Long, RecaudacionResponse> porCancha = new TreeMap<>();
        for (Reserva reserva : finalizadas) {
            Long canchaId = reserva.getCancha().getId();
            String nombre = reserva.getCancha().getNombre();
            BigDecimal total = reserva.getPrecioTotal();
            RecaudacionResponse acumulado = porCancha.get(canchaId);
            if (acumulado == null) {
                porCancha.put(
                        canchaId,
                        new RecaudacionResponse(
                                canchaId, nombre, total.setScale(2, RoundingMode.HALF_UP)));
            } else {
                porCancha.put(
                        canchaId,
                        new RecaudacionResponse(
                                canchaId,
                                nombre,
                                acumulado
                                        .total()
                                        .add(total)
                                        .setScale(2, RoundingMode.HALF_UP)));
            }
        }
        return new ArrayList<>(porCancha.values());
    }

    private Cancha buscarEntidad(Long id) {
        return canchaRepository
                .findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe la cancha " + id));
    }

    private void copiarDatos(Cancha cancha, CanchaRequest request) {
        cancha.setNombre(request.nombre());
        cancha.setDeporte(request.deporte());
        cancha.setPrecioHora(request.precioHora());
    }
}
