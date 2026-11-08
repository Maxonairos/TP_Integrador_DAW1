package ar.edu.undec.tp_integrador_daw1.dto;

import ar.edu.undec.tp_integrador_daw1.entity.EstadoReserva;
import jakarta.validation.constraints.NotNull;

public record EstadoRequest(
        @NotNull(message = "es obligatorio") EstadoReserva estado) {
}
