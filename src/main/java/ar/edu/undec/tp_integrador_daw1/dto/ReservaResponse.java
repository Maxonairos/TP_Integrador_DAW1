package ar.edu.undec.tp_integrador_daw1.dto;

import ar.edu.undec.tp_integrador_daw1.entity.EstadoReserva;
import ar.edu.undec.tp_integrador_daw1.entity.Reserva;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record ReservaResponse(
        Long id,
        Long canchaId,
        String canchaNombre,
        Long clienteId,
        String clienteNombre,
        LocalDateTime inicio,
        Integer horas,
        BigDecimal precioTotal,
        BigDecimal recargo,
        EstadoReserva estado) {

    public static ReservaResponse desde(Reserva reserva) {
        return new ReservaResponse(
                reserva.getId(),
                reserva.getCancha().getId(),
                reserva.getCancha().getNombre(),
                reserva.getCliente().getId(),
                reserva.getCliente().getNombre(),
                reserva.getInicio(),
                reserva.getHoras(),
                reserva.getPrecioTotal(),
                reserva.getRecargo() == null ? BigDecimal.ZERO : reserva.getRecargo(),
                reserva.getEstado());
    }
}
